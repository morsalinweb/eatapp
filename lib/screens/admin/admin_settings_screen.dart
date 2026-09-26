// path: lib/screens/admin/admin_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../auth/role_select_screen.dart';
import '../shared/change_password_screen.dart';
import '../shared/delete_account_screen.dart';
import '../shared/privacy_policy_screen.dart';
import 'admin_manage_users_screen.dart';
import 'admin_manage_vendors_screen.dart';
import 'admin_suspended_accounts_screen.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.people_outline, color: AppColors.neon),
              title: const Text('Manage Users'),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const AdminManageUsersScreen())),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.storefront_outlined, color: AppColors.neon),
              title: const Text('Manage Vendors'),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const AdminManageVendorsScreen())),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.block_outlined, color: AppColors.danger),
              title: const Text('Suspended Accounts'),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const AdminSuspendedAccountsScreen())),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_outline, color: AppColors.neon),
              title: const Text('Change Password'),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.shield_outlined, color: AppColors.neon),
              title: const Text('Privacy & Policy'),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_forever_outlined, color: AppColors.danger),
              title: const Text('Delete Account', style: TextStyle(color: AppColors.danger)),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const DeleteAccountScreen())),
            ),
          ),
          const SizedBox(height: 20),
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
}