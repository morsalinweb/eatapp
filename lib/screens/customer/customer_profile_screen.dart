// path: lib/screens/customer/customer_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/alien_avatar.dart';
import '../auth/role_select_screen.dart';
import '../shared/change_password_screen.dart';
import '../shared/delete_account_screen.dart';
import '../shared/help_center_screen.dart';
import '../shared/privacy_policy_screen.dart';
import 'customer_edit_profile_screen.dart';
import 'my_reports_screen.dart';
import 'notification_settings_screen.dart';

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                AlienAvatar(size: 88, glow: true, imageUrl: user?.avatarUrl),
                const SizedBox(height: 12),
                Text(user?.name ?? 'Guest',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 18)),
                Text(user?.email ?? '',
                    style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _tile(
            context,
            Icons.person_outline,
            'Edit Profile',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const CustomerEditProfileScreen())),
          ),
          _tile(
            context,
            Icons.lock_outline,
            'Change Password',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
          ),
          _tile(
            context,
            Icons.notifications_none,
            'Notification Settings',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const NotificationSettingsScreen())),
          ),
          _tile(
            context,
            Icons.shield_outlined,
            'Privacy & Security',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const PrivacyPolicyScreen(title: 'Privacy & Security'))),
          ),
          _tile(
            context,
            Icons.flag_outlined,
            'My Reports',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const MyReportsScreen())),
          ),
          _tile(
            context,
            Icons.help_outline,
            'Help Center',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const HelpCenterScreen())),
          ),
          _tile(
            context,
            Icons.logout,
            'Logout',
            isDanger: true,
            onTap: () async {
              await context.read<AuthProvider>().logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const RoleSelectScreen()),
                (route) => false,
              );
            },
          ),
          const SizedBox(height: 4),
          _tile(
            context,
            Icons.delete_forever_outlined,
            'Delete Account',
            isDanger: true,
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const DeleteAccountScreen())),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title,
      {bool isDanger = false, VoidCallback? onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: isDanger ? AppColors.danger : AppColors.neon),
        title: Text(title,
            style: TextStyle(
                color: isDanger ? AppColors.danger : AppColors.textPrimary,
                fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
        onTap: onTap ?? () {},
      ),
    );
  }
}