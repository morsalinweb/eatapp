// path: lib/screens/customer/live_map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/maps_launcher.dart';
import '../../models/models.dart';
import '../../providers/chat_provider.dart';
import '../../providers/vendor_provider.dart';
import '../../widgets/alien_avatar.dart';
import '../../widgets/category_filter_bar.dart';
import '../../widgets/live_badge.dart';
import '../chat/chat_thread_screen.dart';
import 'vendor_profile_screen.dart';

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  static const double _tapRadiusMeters = 300;

  final MapController _mapController = MapController();
  Vendor? _selectedVendor;
  final _searchController = TextEditingController();
  bool _initialLoadStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialLoadStarted) {
      _initialLoadStarted = true;
      final vendorProvider = context.read<VendorProvider>();
      vendorProvider.loadAllVendorsWorldwide().then((_) {
        if (!mounted) return;
        _mapController.move(
          LatLng(vendorProvider.deviceLat, vendorProvider.deviceLng),
          14.2,
        );
      });
    }
  }

  @override
  void dispose() {
    context.read<VendorProvider>().stopWatchingMap();
    super.dispose();
  }

  void _handleMapTap(LatLng tapped, List<Vendor> liveVendors) {
    final nearby = liveVendors.where((v) => v.lat != null && v.lng != null).map((v) {
      final distance = Geolocator.distanceBetween(
        tapped.latitude,
        tapped.longitude,
        v.lat!,
        v.lng!,
      );
      return (vendor: v, distance: distance);
    }).where((entry) => entry.distance <= _tapRadiusMeters).toList()
      ..sort((a, b) => a.distance.compareTo(b.distance));

    if (nearby.isEmpty) return;

    if (nearby.length == 1) {
      setState(() => _selectedVendor = nearby.first.vendor);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                '${nearby.length} vendors near this spot',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                itemCount: nearby.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 64),
                itemBuilder: (context, i) {
                  final vendor = nearby[i].vendor;
                  final distanceMeters = nearby[i].distance;
                  return ListTile(
                    leading: AlienAvatar(size: 44, glow: true, imageUrl: vendor.avatarUrl),
                    title: Text(vendor.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      vendor.subCategory,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    trailing: Text(
                      distanceMeters < 1000
                          ? '${distanceMeters.round()} m'
                          : '${(distanceMeters / 1000).toStringAsFixed(1)} km',
                      style: const TextStyle(color: AppColors.neon, fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _selectedVendor = vendor);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vendorProvider = context.watch<VendorProvider>();
    final liveVendors = vendorProvider.filteredMapVendors.where((v) => v.isLive).toList();
    final center = LatLng(vendorProvider.deviceLat, vendorProvider.deviceLng);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 14.2,
              onTap: (tapPosition, point) => _handleMapTap(point, liveVendors),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png?key=${AppConfig.cartoApiKey}',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.eatapp.eat',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: center,
                    width: 26,
                    height: 26,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.withOpacity(0.85),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                  ...liveVendors.where((v) => v.lat != null && v.lng != null).map((v) {
                    return Marker(
                      point: LatLng(v.lat!, v.lng!),
                      width: 54,
                      height: 54,
                      child: GestureDetector(
                        onTap: () => _handleMapTap(LatLng(v.lat!, v.lng!), liveVendors),
                        child: _VendorMarker(vendor: v, isSelected: _selectedVendor?.id == v.id),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          'E.A.T.',
                          style: TextStyle(
                            color: AppColors.neon,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            fontSize: 20,
                            shadows: AppShadows.neonGlow(blur: 10, opacity: 0.6),
                          ),
                        ),
                        const Text('Eats Around Town',
                            style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: vendorProvider.setSearchQuery,
                    decoration: InputDecoration(
                      hintText: 'Search vendors...',
                      prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                      suffixIcon: const Icon(Icons.tune, color: AppColors.textMuted),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                CategoryFilterBar(
                  selected: vendorProvider.activeFilter,
                  onSelect: vendorProvider.setFilter,
                ),
              ],
            ),
          ),

          if (vendorProvider.mapLoading)
            const Positioned.fill(
              child: IgnorePointer(
                child: Center(child: CircularProgressIndicator(color: AppColors.neon)),
              ),
            ),

          if (!vendorProvider.mapLoading && vendorProvider.mapError != null)
            Positioned(
              top: 160,
              left: 16,
              right: 16,
              child: _ErrorBanner(
                message: vendorProvider.mapError!,
                onRetry: () => vendorProvider.loadAllVendorsWorldwide(),
              ),
            ),

          Positioned(
            right: 16,
            bottom: _selectedVendor != null ? 250 : 24,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: AppColors.surfaceRaised,
              onPressed: () => _mapController.move(center, 14.2),
              child: const Icon(Icons.my_location, color: AppColors.neon),
            ),
          ),

          if (_selectedVendor != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _VendorPreviewCard(
                vendor: _selectedVendor!,
                onViewProfile: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => VendorProfileScreen(vendor: _selectedVendor!),
                  ));
                },
                onMessage: () async {
                  final thread = await context.read<ChatProvider>().startThreadWithVendor(
                        _selectedVendor!.id,
                        _selectedVendor!.name,
                        vendorAvatarUrl: _selectedVendor!.avatarUrl,
                      );
                  if (!context.mounted || thread == null) return;
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ChatThreadScreen(threadTitle: _selectedVendor!.name, thread: thread),
                  ));
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 12.5))),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _VendorMarker extends StatelessWidget {
  final Vendor vendor;
  final bool isSelected;
  const _VendorMarker({required this.vendor, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceRaised,
        border: Border.all(color: AppColors.neon, width: isSelected ? 2.6 : 1.6),
        boxShadow: AppShadows.neonGlow(opacity: isSelected ? 0.55 : 0.3, blur: isSelected ? 20 : 12),
      ),
      padding: const EdgeInsets.all(6),
      child: AlienAvatar(size: 30, imageUrl: vendor.avatarUrl),
    );
  }
}

class _VendorPreviewCard extends StatelessWidget {
  final Vendor vendor;
  final VoidCallback onViewProfile;
  final VoidCallback onMessage;

  const _VendorPreviewCard({
    required this.vendor,
    required this.onViewProfile,
    required this.onMessage,
  });

  Future<void> _openDirections(BuildContext context) async {
    if (vendor.lat == null || vendor.lng == null) return;
    final opened = await MapsLauncher.openDirections(lat: vendor.lat!, lng: vendor.lng!, label: vendor.name);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Maps.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendorProvider = context.watch<VendorProvider>();
    final isFav = vendorProvider.isFavorite(vendor.id);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.subtleCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AlienAvatar(size: 54, glow: true, imageUrl: vendor.avatarUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(vendor.name,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                        const LiveBadge(),
                      ],
                    ),
                    Text(vendor.subCategory,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    // Now tappable — same tap-to-navigate destination as
                    // the info row on the full profile screen.
                    InkWell(
                      onTap: () => _openDirections(context),
                      child: Row(
                        children: [
                          Text(
                            '${vendor.distanceMiles.toStringAsFixed(1)} mi away • Get Directions',
                            style: const TextStyle(
                              color: AppColors.neon,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.navigation, size: 13, color: AppColors.neon),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? AppColors.neon : AppColors.textMuted,
                ),
                onPressed: () => vendorProvider.toggleFavorite(vendor.id),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Serving up the best ${vendor.category.label.toLowerCase()}!',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(onPressed: onViewProfile, child: const Text('View Profile')),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(onPressed: onMessage, child: const Text('Message')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}