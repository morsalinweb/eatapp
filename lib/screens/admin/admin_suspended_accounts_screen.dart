// path: lib/screens/admin/admin_suspended_accounts_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_dialogs.dart';
import '../../providers/admin_provider.dart';

class AdminSuspendedAccountsScreen extends StatefulWidget {
  const AdminSuspendedAccountsScreen({super.key});

  @override
  State<AdminSuspendedAccountsScreen> createState() => _AdminSuspendedAccountsScreenState();
}

class _AdminSuspendedAccountsScreenState extends State<AdminSuspendedAccountsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AdminProvider>().loadUsers());
  }

  Future<void> _reinstate(String userId, String name) async {
    final admin = context.read<AdminProvider>();
    final ok = await admin.reinstateUser(userId);
    if (!mounted) return;
    await AppDialogs.showMessage(
      context,
      ok ? '$name reinstated.' : (admin.error ?? 'Could not reinstate.'),
      isError: !ok,
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final suspended = admin.users.where((u) => u.isSuspended).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Suspended Accounts')),
      body: admin.loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.neon))
          : suspended.isEmpty
              ? const Center(
                  child: Text('No suspended accounts 🎉', style: TextStyle(color: AppColors.textSecondary)))
              : RefreshIndicator(
                  color: AppColors.neon,
                  onRefresh: () => context.read<AdminProvider>().loadUsers(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: suspended.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final user = suspended[i];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.danger),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  Text(user.email,
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  const SizedBox(height: 2),
                                  Text(user.role.name.toUpperCase(),
                                      style: const TextStyle(
                                          color: AppColors.textMuted, fontSize: 10.5, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => _reinstate(user.id, user.name),
                              child: const Text('Reinstate'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}