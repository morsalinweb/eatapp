// path: lib/screens/admin/admin_applications_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/admin_provider.dart';

class AdminApplicationsScreen extends StatefulWidget {
  const AdminApplicationsScreen({super.key});

  @override
  State<AdminApplicationsScreen> createState() => _AdminApplicationsScreenState();
}

class _AdminApplicationsScreenState extends State<AdminApplicationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadApplications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final pending = admin.applications
        .where((a) => a.status == VendorStatus.pending)
        .toList();
    final reviewed = admin.applications
        .where((a) => a.status != VendorStatus.pending)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Applications')),
      body: admin.loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.neon))
          : RefreshIndicator(
              color: AppColors.neon,
              onRefresh: () => admin.loadApplications(),
              child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('PENDING (${pending.length})',
              style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
          const SizedBox(height: 10),
          if (pending.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('No pending applications 🎉',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          ...pending.map((app) => _AppCard(app: app)),
          if (reviewed.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('REVIEWED',
                style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1)),
            const SizedBox(height: 10),
            ...reviewed.map((app) => _AppCard(app: app)),
          ],
        ],
              ),
            ),
    );
  }
}

class _AppCard extends StatelessWidget {
  final VendorApplication app;
  const _AppCard({required this.app});

  Color _statusColor(VendorStatus s) {
    switch (s) {
      case VendorStatus.approved:
        return AppColors.neon;
      case VendorStatus.rejected:
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.read<AdminProvider>();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(app.businessName,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(app.status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _statusColor(app.status)),
                ),
                child: Text(app.status.name.toUpperCase(),
                    style: TextStyle(
                        color: _statusColor(app.status),
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('${app.applicantName} • ${app.email}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text('Category: ${app.category.label}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Text(app.description,
              style: const TextStyle(fontSize: 12.5, height: 1.4)),
          if (app.status == VendorStatus.pending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger)),
                    onPressed: () => admin.reject(app),
                    child: const Text('Reject', style: TextStyle(color: AppColors.danger)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => admin.approve(app),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
