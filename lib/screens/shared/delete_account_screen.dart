// path: lib/screens/shared/delete_account_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_dialogs.dart';
import '../../providers/auth_provider.dart';
import '../auth/role_select_screen.dart';

/// Shared account-deletion warning + confirmation screen, used from
/// customer, vendor, and admin settings alike. Deleting here calls
/// AuthProvider.deleteAccount(), which hits DELETE /auth/me and removes
/// the account and every piece of associated data server-side.
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _deleting = false;

  Future<void> _confirmAndDelete() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Delete your account?'),
            content: const Text(
              "This is permanent. Your profile, messages, favorites, reports, and (if you're a "
              "vendor) your storefront will all be deleted and cannot be recovered.",
              style: TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete Forever'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    setState(() => _deleting = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.deleteAccount();
    if (!mounted) return;
    setState(() => _deleting = false);

    if (ok) {
      await AppDialogs.showMessage(
        context,
        'Your account and all associated data have been permanently deleted.',
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RoleSelectScreen()),
        (route) => false,
      );
    } else {
      await AppDialogs.showMessage(
        context,
        auth.error ?? 'Could not delete your account. Please try again.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delete Account')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.08),
                border: Border.all(color: AppColors.danger),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.danger),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Deleting your account is permanent and cannot be undone.',
                      style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('What gets deleted', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: const [
                  _DeleteItem('Your profile', 'Name, email, phone number, and profile photo'),
                  _DeleteItem('Vendor storefront',
                      "If you're a vendor: your business listing, description, and photos"),
                  _DeleteItem('Messages', "All chat conversations you're part of"),
                  _DeleteItem('Favorites', "Vendors you've saved"),
                  _DeleteItem('Reports',
                      "Reports you've filed, and — if you're a vendor — reports filed about you"),
                  _DeleteItem('Location data', 'Your last known location on file'),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _deleting ? null : _confirmAndDelete,
                child: _deleting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('DELETE ACCOUNT',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteItem extends StatelessWidget {
  final String title;
  final String subtitle;
  const _DeleteItem(this.title, this.subtitle);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.close, size: 16, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}