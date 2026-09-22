// path: lib/screens/admin/admin_locations_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/alien_avatar.dart';

/// Shows the CURRENT location of every live vendor and every customer with
/// a recorded position — a live snapshot, not a movement history.
///
/// Multiple people are often at (or very near) the exact same coordinates
/// on a real map — a marker-per-person layout then only lets you reach
/// whichever one happens to render on top. Instead, tapping ANYWHERE on
/// the map (or on a specific marker) shows every person within a small
/// radius of that point, sorted nearest-first, in a bottom sheet.
class AdminLocationsScreen extends StatefulWidget {
  const AdminLocationsScreen({super.key});

  @override
  State<AdminLocationsScreen> createState() => _AdminLocationsScreenState();
}

class _AdminLocationsScreenState extends State<AdminLocationsScreen> {
  /// How close two points need to be to count as "the same cluster" when
  /// tapped — generous enough to catch markers that visually overlap at
  /// typical zoom levels, without pulling in someone genuinely blocks away.
  static const double _clusterRadiusMeters = 120;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadLocations();
    });
  }

  void _showNearby(LatLng tappedPoint, List<AdminLocationPoint> allPoints) {
    final withDistance = allPoints
        .map((p) => (
              point: p,
              distance: Geolocator.distanceBetween(
                tappedPoint.latitude,
                tappedPoint.longitude,
                p.lat,
                p.lng,
              ),
            ))
        .where((entry) => entry.distance <= _clusterRadiusMeters)
        .toList()
      ..sort((a, b) => a.distance.compareTo(b.distance));

    if (withDistance.isEmpty) return;

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
                withDistance.length == 1
                    ? '1 person here'
                    : '${withDistance.length} people near this spot',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                itemCount: withDistance.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 64),
                itemBuilder: (context, i) {
                  final p = withDistance[i].point;
                  final ringColor = p.isVendor ? AppColors.neon : Colors.blueAccent;
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: ringColor, width: 2)),
                      child: AlienAvatar(size: 40, imageUrl: p.avatarUrl),
                    ),
                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      p.isVendor ? 'Vendor · Live now' : 'Customer',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    trailing: p.lastUpdatedAt != null
                        ? Text(
                            _timeLabel(p.lastUpdatedAt!),
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                          )
                        : null,
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

  String _timeLabel(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final points = admin.locations;
    final center = points.isNotEmpty
        ? LatLng(points.first.lat, points.first.lng)
        : LatLng(AppConfig.defaultLat, AppConfig.defaultLng);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Locations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AdminProvider>().loadLocations(),
          ),
        ],
      ),
      body: admin.loading && points.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.neon))
          : Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 12,
                    onTap: (tapPosition, point) => _showNearby(point, points),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png?key=${AppConfig.cartoApiKey}',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.eatapp.eat',
                    ),
                    MarkerLayer(
                      markers: points.map((p) {
                        return Marker(
                          point: LatLng(p.lat, p.lng),
                          width: 46,
                          height: 46,
                          child: GestureDetector(
                            // Tapping a specific marker still surfaces
                            // everyone near IT, not just this one person —
                            // covers the case of several markers stacked
                            // at the same spot.
                            onTap: () => _showNearby(LatLng(p.lat, p.lng), points),
                            child: _LocationMarker(point: p),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        _legendDot(AppColors.neon),
                        const SizedBox(width: 6),
                        const Text('Vendors', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(width: 16),
                        _legendDot(Colors.blueAccent),
                        const SizedBox(width: 6),
                        const Text('Customers', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const Spacer(),
                        Text('${points.length} shown',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.card.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Text(
                        'Tap anywhere on the map to see who\'s there',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _legendDot(Color color) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _LocationMarker extends StatelessWidget {
  final AdminLocationPoint point;
  const _LocationMarker({required this.point});

  @override
  Widget build(BuildContext context) {
    // Vendor ring = neon (E.A.T.'s brand lime-green); customer ring = blue —
    // matches the legend shown at the top of the map.
    final ringColor = point.isVendor ? AppColors.neon : Colors.blueAccent;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: 2.4),
        boxShadow: [BoxShadow(color: ringColor.withOpacity(0.5), blurRadius: 8)],
      ),
      child: AlienAvatar(size: 34, imageUrl: point.avatarUrl),
    );
  }
}