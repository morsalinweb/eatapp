// path: lib/screens/admin/admin_manage_vendors_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_dialogs.dart';
import '../../providers/admin_provider.dart';

class AdminManageVendorsScreen extends StatefulWidget {
  const AdminManageVendorsScreen({super.key});

  @override
  State<AdminManageVendorsScreen> createState() => _AdminManageVendorsScreenState();
}

class _AdminManageVendorsScreenState extends State<AdminManageVendorsScreen> {
  bool? _suspendedFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadVendorsAdmin();
    });
  }

  Future<void> _toggleSuspend(AdminVendorSummary vendor) async {
    final admin = context.read<AdminProvider>();
    final wasSuspended = vendor.isSuspended;
    final ok = wasSuspended ? await admin.reinstateUser(vendor.ownerId) : await admin.suspendUser(vendor.ownerId);
    if (!mounted) return;
    await AppDialogs.showMessage(
      context,
      ok
          ? (wasSuspended ? '${vendor.name} reinstated.' : '${vendor.name} suspended.')
          : (admin.error ?? 'Something went wrong.'),
      isError: !ok,
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final vendors = admin.vendorsAdmin.where((v) {
      if (_suspendedFilter == null) return true;
      return v.isSuspended == _suspendedFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Vendors')),
      body: Column(
        children: [
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _filterChip('All', null),
                const SizedBox(width: 8),
                _filterChip('Active', false),
                const SizedBox(width: 8),
                _filterChip('Suspended', true),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: admin.loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.neon))
                : vendors.isEmpty
                    ? const Center(
                        child: Text('No vendors found', style: TextStyle(color: AppColors.textSecondary)))
                    : RefreshIndicator(
                        color: AppColors.neon,
                        onRefresh: () => context.read<AdminProvider>().loadVendorsAdmin(),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          itemCount: vendors.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final vendor = vendors[i];
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: vendor.isSuspended ? AppColors.danger : AppColors.border),
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
                                              child: Text(vendor.name,
                                                  style: const TextStyle(fontWeight: FontWeight.w700)),
                                            ),
                                            if (vendor.isLive)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.neon.withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(color: AppColors.neon),
                                                ),
                                                child: const Text('LIVE',
                                                    style: TextStyle(
                                                        fontSize: 9.5,
                                                        color: AppColors.neon,
                                                        fontWeight: FontWeight.w700)),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(vendor.category.name,
                                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                        if (vendor.ownerEmail.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.email_outlined, size: 12, color: AppColors.textMuted),
                                              const SizedBox(width: 4),
                                              Text(vendor.ownerEmail,
                                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                            ],
                                          ),
                                        ],
                                        if (vendor.isSuspended) ...[
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
                                          color: vendor.isSuspended ? AppColors.neon : AppColors.danger),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      minimumSize: const Size(0, 32),
                                    ),
                                    onPressed: vendor.ownerId.isEmpty ? null : () => _toggleSuspend(vendor),
                                    child: Text(
                                      vendor.isSuspended ? 'Reinstate' : 'Suspend',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: vendor.isSuspended ? AppColors.neon : AppColors.danger),
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

  Widget _filterChip(String label, bool? value) {
    final isSelected = _suspendedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.neon,
      backgroundColor: AppColors.surfaceRaised,
      labelStyle: TextStyle(
          color: isSelected ? Colors.black : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 12.5),
      onSelected: (_) => setState(() => _suspendedFilter = value),
    );
  }
}