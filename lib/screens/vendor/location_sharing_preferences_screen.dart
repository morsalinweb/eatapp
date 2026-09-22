// path: lib/screens/vendor/location_sharing_preferences_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/vendor_provider.dart';

/// Real live-sharing status (reuses VendorProvider, same as the "Go Live"
/// tab) plus plain-language notes on what's shared and when. There's no
/// backend support yet for things like scheduled auto-stop or approximate
/// location, so this screen sticks to what's actually true today rather
/// than fake toggles.
class LocationSharingPreferencesScreen extends StatelessWidget {
  const LocationSharingPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vendorProvider = context.watch<VendorProvider>();
    final isLive = vendorProvider.isMyVendorLive;

    return Scaffold(
      appBar: AppBar(title: const Text('Location Sharing Preferences')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isLive ? AppColors.neon : AppColors.border),
            ),
            child: Row(
              children: [
                Icon(isLive ? Icons.podcasts : Icons.podcasts_outlined,
                    color: isLive ? AppColors.neon : AppColors.textMuted),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isLive ? 'Currently sharing location' : 'Not sharing location',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(
                        isLive
                            ? 'Customers within your service area can see you on the live map.'
                            : 'Turn this on from the Go Live tab whenever you want to appear on the map.',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('HOW IT WORKS',
              style: TextStyle(
                  color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
          const SizedBox(height: 10),
          _infoTile(
            Icons.gps_fixed,
            'Live while broadcasting',
            "Your device sends an updated GPS position roughly every 12 seconds while you're live, so "
                'your marker moves in near real time.',
          ),
          _infoTile(
            Icons.visibility_off_outlined,
            'Hidden by default',
            'Your exact location is never visible to customers unless you\'ve tapped "Go Live" — '
                'closing the app or tapping "Stop Sharing" removes you from the map immediately.',
          ),
          _infoTile(
            Icons.shield_outlined,
            "Not stored after you stop",
            "Your live position isn't kept once you stop sharing — only that you were live, and when.",
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.neon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}