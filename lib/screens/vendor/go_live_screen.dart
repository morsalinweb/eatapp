// path: lib/screens/vendor/go_live_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_dialogs.dart';
import '../../providers/vendor_provider.dart';
import '../../widgets/alien_avatar.dart';
import '../../widgets/live_badge.dart';

class GoLiveScreen extends StatefulWidget {
  const GoLiveScreen({super.key});

  @override
  State<GoLiveScreen> createState() => _GoLiveScreenState();
}

class _GoLiveScreenState extends State<GoLiveScreen> {
  final MapController _mapController = MapController();
  LatLng? _lastCenteredOn;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<VendorProvider>();
      if (provider.myVendor == null) provider.loadMyVendor();
      provider.refreshDeviceLocation();
    });
  }

  void _recenterIfNeeded(LatLng center) {
    if (_lastCenteredOn == center) return;
    _lastCenteredOn = center;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _mapController.move(center, 14.5);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vendorProvider = context.watch<VendorProvider>();
    final isLive = vendorProvider.isMyVendorLive;
    final center = LatLng(vendorProvider.deviceLat, vendorProvider.deviceLng);
    final vendorName = vendorProvider.myVendor?.name ?? 'Your business';

    _recenterIfNeeded(center);

    return Scaffold(
      appBar: AppBar(title: const Text('Go Live')),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                IgnorePointer(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: 14.5,
                      interactionOptions:
                          const InteractionOptions(flags: InteractiveFlag.none),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png?key=${AppConfig.cartoApiKey}',
                        subdomains: const ['a', 'b', 'c', 'd'],
                        userAgentPackageName: 'com.eatapp.eat',
                      ),
                      if (isLive)
                        MarkerLayer(markers: [
                          Marker(
                            point: center,
                            width: 90,
                            height: 90,
                            child: _PulsingRadius(),
                          ),
                        ]),
                    ],
                  ),
                ),
                if (!isLive)
                  Container(color: Colors.black.withOpacity(0.55)),
                if (!isLive)
                  const Center(
                    child: Text(
                      'You\'re offline.\nGo live to broadcast your location.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      AlienAvatar(size: 44, glow: true, imageUrl: vendorProvider.myVendor?.avatarUrl),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(vendorName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 15)),
                            if (isLive) const LiveBadge() else const Text(
                              'Offline',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLive ? AppColors.danger : AppColors.neon,
                      foregroundColor: isLive ? Colors.white : Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    onPressed: () => _confirm(context, vendorProvider, isLive),
                    child: Text(
                      isLive ? 'STOP SHARING LOCATION' : 'GO LIVE',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isLive
                        ? 'Customers within your service area can see you in real time.'
                        : 'When you go live, your GPS location broadcasts on the customer map until you stop.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirm(BuildContext context, VendorProvider provider, bool isLive) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(isLive ? 'Stop sharing location?' : 'Start sharing location?'),
        content: Text(
          isLive
              ? 'You\'ll disappear from the live map immediately.'
              : 'This uses your device GPS and shares your live position with nearby customers.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await provider.setMyVendorLive(!isLive);
              if (!ok && context.mounted && provider.error != null) {
                await AppDialogs.showMessage(context, provider.error!, isError: true);
              }
            },
            child: Text(isLive ? 'STOP' : 'GO LIVE'),
          ),
        ],
      ),
    );
  }
}

class _PulsingRadius extends StatefulWidget {
  @override
  State<_PulsingRadius> createState() => _PulsingRadiusState();
}

class _PulsingRadiusState extends State<_PulsingRadius>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))
        ..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 90 * _controller.value,
              height: 90 * _controller.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neon.withOpacity((1 - _controller.value) * 0.4),
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceRaised,
                border: Border.all(color: AppColors.neon, width: 2),
                boxShadow: AppShadows.neonGlow(opacity: 0.6, blur: 12),
              ),
            ),
          ],
        );
      },
    );
  }
}