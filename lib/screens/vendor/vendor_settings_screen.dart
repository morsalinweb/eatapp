// path: lib/screens/vendor/vendor_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../auth/role_select_screen.dart';
import '../shared/change_password_screen.dart';
import '../shared/help_center_screen.dart';
import '../shared/privacy_policy_screen.dart';
import 'location_sharing_preferences_screen.dart';
import 'vendor_guidelines_screen.dart';
import 'vendor_profile_edit_screen.dart';

class VendorSettingsScreen extends StatelessWidget {
  const VendorSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _section('ACCOUNT'),
          _tile(
            Icons.person_outline,
            'Account Details',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const VendorProfileEditScreen())),
          ),
          _tile(
            Icons.lock_outline,
            'Change Password',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
          ),
          const SizedBox(height: 20),
          _section('NOTIFICATIONS'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.neon,
            title: const Text('New message alerts'),
            value: true,
            onChanged: (_) {},
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.neon,
            title: const Text('Go-live reminders'),
            value: true,
            onChanged: (_) {},
          ),
          const SizedBox(height: 20),
          _section('PRIVACY'),
          _tile(
            Icons.location_on_outlined,
            'Location Sharing Preferences',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const LocationSharingPreferencesScreen())),
          ),
          _tile(
            Icons.shield_outlined,
            'Privacy & Policy',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
          ),
          const SizedBox(height: 20),
          _section('SUPPORT'),
          _tile(
            Icons.help_outline,
            'Help Center',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const HelpCenterScreen())),
          ),
          _tile(
            Icons.description_outlined,
            'Vendor Guidelines',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const VendorGuidelinesScreen())),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout, color: AppColors.danger),
              label: const Text('Logout', style: TextStyle(color: AppColors.danger)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger)),
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const RoleSelectScreen()),
                  (route) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(title,
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1)),
      );

  Widget _tile(IconData icon, String title, {VoidCallback? onTap}) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: Icon(icon, color: AppColors.neon),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
          onTap: onTap ?? () {},
        ),
      );
}