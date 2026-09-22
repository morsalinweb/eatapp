// path: lib/screens/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/admin_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard'), automaticallyImplyLeading: false),
      body: RefreshIndicator(
        color: AppColors.neon,
        onRefresh: () => admin.loadStats(),
        child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.5,
            children: [
              _statCard('Total Users', '${admin.totalUsers}', Icons.people_outline, AppColors.neon),
              _statCard('Total Vendors', '${admin.totalVendors}', Icons.storefront_outlined, AppColors.neon),
              _statCard('Pending Applications', '${admin.pendingApplications}', Icons.hourglass_top_outlined, AppColors.warning),
              _statCard('Vendors LIVE Now', '${admin.liveVendorsNow}', Icons.podcasts_outlined, AppColors.neon),
              _statCard('Open Reports', '${admin.openReports}', Icons.flag_outlined, AppColors.danger),
              _statCard('Suspended', '${admin.suspendedAccounts}', Icons.block_outlined, AppColors.danger),
            ],
          ),
          const SizedBox(height: 24),
          const Text('QUICK ACTIONS',
              style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.assignment_turned_in_outlined, color: AppColors.neon),
              title: const Text('Review vendor applications'),
              subtitle: Text('${admin.pendingApplications} awaiting review'),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
              onTap: () {},
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.flag_outlined, color: AppColors.danger),
              title: const Text('Handle open reports'),
              subtitle: Text('${admin.openReports} unresolved'),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
              onTap: () {},
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
        ],
      ),
    );
  }
}
