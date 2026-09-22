// path: lib/screens/admin/admin_reports_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_dialogs.dart';
import '../../models/models.dart';
import '../../providers/admin_provider.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadReports();
    });
  }

  Future<void> _toggleSuspend(VendorReport report) async {
    if (report.vendorOwnerId.isEmpty) {
      await AppDialogs.showMessage(
        context,
        'No vendor account is linked to this report. Pull to refresh and try again.',
        isError: true,
      );
      return;
    }

    final wasSuspended = report.vendorSuspended;

    if (!wasSuspended) {
      final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('Suspend this vendor?'),
              content: Text(
                '${report.vendorName} will be pulled off the live map immediately and blocked from '
                'logging in until reinstated.',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Suspend'),
                ),
              ],
            ),
          ) ??
          false;
      if (!confirmed) return;
    }

    final admin = context.read<AdminProvider>();
    final ok = wasSuspended
        ? await admin.reinstateUser(report.vendorOwnerId)
        : await admin.suspendUser(report.vendorOwnerId, reason: 'Reported: ${report.reason}');

    if (!mounted) return;
    await AppDialogs.showMessage(
      context,
      ok
          ? (wasSuspended ? '${report.vendorName} reinstated.' : '${report.vendorName} has been suspended.')
          : 'Could not update vendor: ${admin.error ?? 'unknown error'}',
      isError: !ok,
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: admin.loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.neon))
          : admin.reports.isEmpty
          ? const Center(
              child: Text('No reports', style: TextStyle(color: AppColors.textSecondary)))
          : RefreshIndicator(
              color: AppColors.neon,
              onRefresh: () => admin.loadReports(),
              child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: admin.reports.length,
              itemBuilder: (context, i) {
                final report = admin.reports[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: report.resolved ? AppColors.border : AppColors.danger,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(report.vendorName,
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          Text(
                            DateFormat('MMM d, h:mm a').format(report.reportedAt),
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                      if (report.vendorEmail.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.email_outlined, size: 13, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(report.vendorEmail,
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text('Reported by ${report.reporterName}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 8),
                      Text(report.reason, style: const TextStyle(fontSize: 13)),
                      if (report.vendorSuspended) ...[
                        const SizedBox(height: 8),
                        const Text('🚫 VENDOR SUSPENDED',
                            style: TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.w700)),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _toggleSuspend(report),
                              style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                      color: report.vendorSuspended ? AppColors.neon : AppColors.danger)),
                              child: Text(
                                report.vendorSuspended ? 'Reinstate Vendor' : 'Suspend Vendor',
                                style: TextStyle(
                                    color: report.vendorSuspended ? AppColors.neon : AppColors.danger),
                              ),
                            ),
                          ),
                          if (!report.resolved) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => admin.resolveReport(report),
                                child: const Text('Mark Resolved'),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (report.resolved) ...[
                        const SizedBox(height: 8),
                        const Text('✓ Resolved',
                            style: TextStyle(color: AppColors.neon, fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                );
              },
              ),
            ),
    );
  }
}