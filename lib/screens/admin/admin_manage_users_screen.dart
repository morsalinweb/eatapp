// path: lib/screens/admin/admin_manage_users_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_dialogs.dart';
import '../../models/models.dart';
import '../../providers/admin_provider.dart';

class AdminManageUsersScreen extends StatefulWidget {
  const AdminManageUsersScreen({super.key});

  @override
  State<AdminManageUsersScreen> createState() => _AdminManageUsersScreenState();
}

class _AdminManageUsersScreenState extends State<AdminManageUsersScreen> {
  UserRole? _roleFilter;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() {
    return context.read<AdminProvider>().loadUsers(
          role: _roleFilter == null ? null : userRoleToApi(_roleFilter!),
          query: _searchController.text.trim(),
        );
  }

  Future<void> _toggleSuspend(AppUser user) async {
    final admin = context.read<AdminProvider>();
    final wasSuspended = user.isSuspended;
    final ok = wasSuspended ? await admin.reinstateUser(user.id) : await admin.suspendUser(user.id);
    if (!mounted) return;
    await AppDialogs.showMessage(
      context,
      ok
          ? (wasSuspended ? '${user.name} reinstated.' : '${user.name} suspended.')
          : (admin.error ?? 'Something went wrong.'),
      isError: !ok,
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _reload(),
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward, color: AppColors.textMuted),
                  onPressed: _reload,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _filterChip('All', null),
                const SizedBox(width: 8),
                _filterChip('Customers', UserRole.customer),
                const SizedBox(width: 8),
                _filterChip('Vendors', UserRole.vendor),
                const SizedBox(width: 8),
                _filterChip('Admins', UserRole.admin),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: admin.loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.neon))
                : admin.users.isEmpty
                    ? const Center(
                        child: Text('No users found', style: TextStyle(color: AppColors.textSecondary)))
                    : RefreshIndicator(
                        color: AppColors.neon,
                        onRefresh: _reload,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          itemCount: admin.users.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final user = admin.users[i];
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: user.isSuspended ? AppColors.danger : AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(user.name,
                                                  style: const TextStyle(fontWeight: FontWeight.w700)),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.surfaceRaised,
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(user.role.name.toUpperCase(),
                                                  style: const TextStyle(
                                                      fontSize: 9.5,
                                                      color: AppColors.textSecondary,
                                                      fontWeight: FontWeight.w700)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(user.email,
                                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                        if (user.isSuspended) ...[
                                          const SizedBox(height: 4),
                                          const Text('SUSPENDED',
                                              style: TextStyle(
                                                  color: AppColors.danger,
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w700)),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                          color: user.isSuspended ? AppColors.neon : AppColors.danger),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      minimumSize: const Size(0, 32),
                                    ),
                                    onPressed: () => _toggleSuspend(user),
                                    child: Text(
                                      user.isSuspended ? 'Reinstate' : 'Suspend',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: user.isSuspended ? AppColors.neon : AppColors.danger),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, UserRole? role) {
    final isSelected = _roleFilter == role;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.neon,
      backgroundColor: AppColors.surfaceRaised,
      labelStyle: TextStyle(
          color: isSelected ? Colors.black : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 12.5),
      onSelected: (_) {
        setState(() => _roleFilter = role);
        _reload();
      },
    );
  }
}