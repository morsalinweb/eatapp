// path: lib/providers/vendor_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../core/config/app_config.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../services/socket_service.dart';

/// Drives BOTH the customer map and the customer Nearby list, but they now
/// pull from two genuinely different queries against the same backend
/// endpoint:
///
///  - "Nearby" (`loadNearbyVendors` / `_vendors`) — the backend's default
///    search radius (an env var on the server, ~8km unless changed), for
///    "vendors actually worth walking/driving to."
///  - The live map (`loadAllVendorsWorldwide` / `_mapVendors`) — the SAME
///    `/vendors?lat=&lng=&radius=` endpoint, just called with a radius
///    roughly equal to Earth's circumference, so every live vendor on the
///    planet comes back. Distance is still computed for real from the
///    device's actual position (via the same Postgres function), so
///    "X mi away" stays accurate even for a vendor on the other side of
///    the world — it's just a very large, honest number.
///
/// Realtime socket updates (a vendor going live/moving/going offline) are
/// broadcast by the server to every connected customer regardless of
/// location — there's no server-side geo-filtering on that broadcast — so
/// they only ever patch the worldwide map list, not the radius-limited
/// Nearby list. The Nearby list is purely a REST snapshot, refreshed
/// whenever that screen's retry/reload path runs.
class VendorProvider extends ChangeNotifier {
  /// Roughly Earth's circumference — passing this as the search radius
  /// effectively means "no distance limit," since nothing on Earth can be
  /// farther than this from any point on it.
  static const double _worldwideRadiusMeters = 40075000;

  List<Vendor> _vendors = []; // nearby, radius-limited — feeds Nearby + Favorites
  List<Vendor> _mapVendors = []; // worldwide — feeds the live map only

  VendorCategory? _activeFilter;
  String _searchQuery = '';
  bool _loading = false;
  bool _mapLoading = false;
  String? _error;
  String? _mapError;

  double? _deviceLat;
  double? _deviceLng;

  Vendor? _myVendor;
  Timer? _pingTimer;

  final Set<String> _favoriteIds = {};

  List<Vendor> get allVendors => _vendors;
  List<Vendor> get mapVendors => _mapVendors;
  bool get loading => _loading;
  bool get mapLoading => _mapLoading;
  String? get error => _error;
  String? get mapError => _mapError;
  VendorCategory? get activeFilter => _activeFilter;
  Set<String> get favoriteIds => _favoriteIds;
  Vendor? get myVendor => _myVendor;
  bool get isMyVendorLive => _myVendor?.isLive ?? false;
  double get deviceLat => _deviceLat ?? AppConfig.defaultLat;
  double get deviceLng => _deviceLng ?? AppConfig.defaultLng;

  List<Vendor> _applyFilters(List<Vendor> source) {
    return source.where((v) {
      final matchesCategory = _activeFilter == null || v.category == _activeFilter;
      final matchesQuery = _searchQuery.isEmpty ||
          v.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          v.subCategory.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList()
      ..sort((a, b) => a.distanceMiles.compareTo(b.distanceMiles));
  }

  /// The Nearby screen's list — radius-limited, distance-sorted.
  List<Vendor> get filteredVendors => _applyFilters(_vendors);

  /// The map's list — worldwide, distance-sorted (so nearer markers still
  /// come first in anything that iterates them, even though the map
  /// itself doesn't care about list order).
  List<Vendor> get filteredMapVendors => _applyFilters(_mapVendors);

  List<Vendor> get favoriteVendors => _vendors.where((v) => _favoriteIds.contains(v.id)).toList();
  bool isFavorite(String vendorId) => _favoriteIds.contains(vendorId);

  void setFilter(VendorCategory? category) {
    _activeFilter = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<Position?> _resolveDevicePosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return null;
      }
      return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (_) {
      return null;
    }
  }

  Future<void> refreshDeviceLocation() async {
    final position = await _resolveDevicePosition();
    if (position == null) return;
    _deviceLat = position.latitude;
    _deviceLng = position.longitude;
    notifyListeners();
  }

  /// Loads vendors within the backend's default search radius — this is
  /// what the Nearby screen shows.
  Future<void> loadNearbyVendors() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final position = await _resolveDevicePosition();
      _deviceLat = position?.latitude;
      _deviceLng = position?.longitude;

      final json = await ApiClient.instance.get('/vendors', query: {
        'lat': deviceLat,
        'lng': deviceLng,
      });
      _vendors = (json['vendors'] as List).map((v) => Vendor.fromNearbyJson(v)).toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Could not load nearby vendors.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Loads EVERY currently-live vendor worldwide — this is what the live
  /// map shows. Also (re)arms the realtime socket subscription, since
  /// vendor:live/location_update/offline broadcasts are global and
  /// naturally belong to this list, not the radius-limited one.
  Future<void> loadAllVendorsWorldwide() async {
    _mapLoading = true;
    _mapError = null;
    notifyListeners();
    try {
      final position = await _resolveDevicePosition();
      _deviceLat = position?.latitude;
      _deviceLng = position?.longitude;

      final json = await ApiClient.instance.get('/vendors', query: {
        'lat': deviceLat,
        'lng': deviceLng,
        'radius': _worldwideRadiusMeters,
      });
      _mapVendors = (json['vendors'] as List).map((v) => Vendor.fromNearbyJson(v)).toList();
      _listenForRealtimeMapUpdates();
    } on ApiException catch (e) {
      _mapError = e.message;
    } catch (e) {
      _mapError = 'Could not load the live map.';
    } finally {
      _mapLoading = false;
      notifyListeners();
    }
  }

  void _listenForRealtimeMapUpdates() {
    SocketService.instance.subscribeToMap();

    // Clear any previously-registered handlers first — calling this again
    // (e.g. the map screen re-mounting) must never leave two copies of the
    // same handler both firing on one event.
    SocketService.instance.offVendorLive();
    SocketService.instance.offVendorLocationUpdate();
    SocketService.instance.offVendorOffline();

    SocketService.instance.onVendorLive((data) {
      final vendorId = data['vendorId'];
      final existingIndex = _mapVendors.indexWhere((v) => v.id == vendorId);
      if (existingIndex == -1) {
        _mapVendors.add(Vendor(
          id: vendorId,
          ownerUserId: '',
          name: data['name'] ?? 'Vendor',
          category: VendorCategory.more,
          subCategory: '',
          description: '',
          isLive: true,
          lat: (data['lat'] as num?)?.toDouble(),
          lng: (data['lng'] as num?)?.toDouble(),
        ));
      } else {
        _mapVendors[existingIndex].isLive = true;
        _mapVendors[existingIndex].lat = (data['lat'] as num?)?.toDouble();
        _mapVendors[existingIndex].lng = (data['lng'] as num?)?.toDouble();
      }
      notifyListeners();
    });

    SocketService.instance.onVendorLocationUpdate((data) {
      final vendorId = data['vendorId'];
      Vendor? vendor;
      for (final v in _mapVendors) {
        if (v.id == vendorId) {
          vendor = v;
          break;
        }
      }
      if (vendor != null) {
        vendor.lat = (data['lat'] as num?)?.toDouble();
        vendor.lng = (data['lng'] as num?)?.toDouble();
        notifyListeners();
      }
    });

    SocketService.instance.onVendorOffline((data) {
      final vendorId = data['vendorId'];
      _mapVendors.removeWhere((v) => v.id == vendorId);
      notifyListeners();
    });
  }

  void stopWatchingMap() {
    SocketService.instance.unsubscribeFromMap();
  }

  // ---------------- Favorites ----------------

  Future<void> loadFavorites() async {
    try {
      final json = await ApiClient.instance.get('/favorites');
      final list = json['favorites'] as List;
      _favoriteIds
        ..clear()
        ..addAll(list.map((f) => f['vendor_id'] as String));

      for (final f in list) {
        final vendorJson = f['vendor'];
        if (vendorJson == null) continue;
        final vendor = Vendor.fromJson(vendorJson);
        final exists = _vendors.any((v) => v.id == vendor.id);
        if (!exists) {
          _vendors.add(vendor);
        }
      }
      notifyListeners();
    } catch (_) {
      // non-fatal — favorites screen will just show what's cached
    }
  }

  Future<void> toggleFavorite(String vendorId) async {
    final wasFavorite = _favoriteIds.contains(vendorId);
    wasFavorite ? _favoriteIds.remove(vendorId) : _favoriteIds.add(vendorId);
    notifyListeners();
    try {
      if (wasFavorite) {
        await ApiClient.instance.delete('/favorites/$vendorId');
      } else {
        await ApiClient.instance.post('/favorites/$vendorId');
      }
    } catch (_) {
      wasFavorite ? _favoriteIds.add(vendorId) : _favoriteIds.remove(vendorId);
      notifyListeners();
    }
  }

  // ---------------- Vendor self-service (go live) ----------------

  Future<void> loadMyVendor() async {
    try {
      final json = await ApiClient.instance.get('/vendors/me/profile');
      _myVendor = Vendor.fromJson(json['vendor']);
      notifyListeners();
    } catch (_) {
      _myVendor = null;
    }
  }

  Future<bool> updateMyVendor(Map<String, dynamic> patch) async {
    try {
      final json = await ApiClient.instance.patch('/vendors/me/profile', body: patch);
      _myVendor = Vendor.fromJson(json['vendor']);
      notifyListeners();
      return true;
    } on ApiException catch (_) {
      return false;
    }
  }

  Future<bool> setMyVendorLive(bool live) async {
    if (!live) {
      _pingTimer?.cancel();
      try {
        await ApiClient.instance.post('/vendors/me/live/stop');
        _myVendor?.isLive = false;
        notifyListeners();
        return true;
      } catch (_) {
        return false;
      }
    }

    final position = await _resolveDevicePosition();
    if (position == null) {
      _error = 'Location permission is required to go live.';
      notifyListeners();
      return false;
    }

    _deviceLat = position.latitude;
    _deviceLng = position.longitude;

    try {
      await ApiClient.instance.post('/vendors/me/live/start', body: {
        'lat': position.latitude,
        'lng': position.longitude,
        'accuracy_meters': position.accuracy,
      });
      _myVendor?.isLive = true;
      notifyListeners();

      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 12), (_) async {
        final p = await _resolveDevicePosition();
        if (p == null) return;
        _deviceLat = p.latitude;
        _deviceLng = p.longitude;
        try {
          await ApiClient.instance.post('/vendors/me/live/ping', body: {
            'lat': p.latitude,
            'lng': p.longitude,
            'accuracy_meters': p.accuracy,
          });
          notifyListeners();
        } catch (_) {
          // transient network hiccups shouldn't kill the live session
        }
      });
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    super.dispose();
  }
}