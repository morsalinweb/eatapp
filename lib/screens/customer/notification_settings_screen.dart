// path: lib/screens/customer/notification_settings_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Preferences here are local to the device for now — there's no backend
/// support yet for persisting per-user notification preferences (actual
/// push delivery isn't wired up server-side either; see the TODO in
/// notifications.controller.js). Kept as real, working toggles so this
/// isn't purely decorative, and ready to wire to a backend later.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _newMessages = true;
  bool _favoriteVendorLive = true;
  bool _promotions = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.neon,
            title: const Text('New messages'),
            subtitle: const Text('Get notified when a vendor replies to you',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            value: _newMessages,
            onChanged: (v) => setState(() => _newMessages = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.neon,
            title: const Text('Favorite vendors go live'),
            subtitle: const Text('Get notified when a vendor you saved starts broadcasting',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            value: _favoriteVendorLive,
            onChanged: (v) => setState(() => _favoriteVendorLive = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.neon,
            title: const Text('Promotions & news'),
            subtitle: const Text('Occasional updates about new vendors and features',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            value: _promotions,
            onChanged: (v) => setState(() => _promotions = v),
          ),
        ],
      ),
    );
  }
}