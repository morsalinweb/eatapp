// path: lib/screens/customer/my_reports_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/api_client.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  bool _loading = true;
  String? _error;
  List<VendorReport> _reports = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final json = await ApiClient.instance.get('/reports/me');
      _reports = (json['reports'] as List).map((r) => VendorReport.fromJson(r)).toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Could not load your reports.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Reports')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.neon))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : _reports.isEmpty
                  ? const Center(
                      child: Text("You haven't reported anyone",
                          style: TextStyle(color: AppColors.textSecondary)),
                    )
                  : RefreshIndicator(
                      color: AppColors.neon,
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _reports.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final report = _reports[i];
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
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(report.vendorName,
                                          style: const TextStyle(fontWeight: FontWeight.w700)),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: (report.resolved ? AppColors.neon : AppColors.warning)
                                            .withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color: report.resolved ? AppColors.neon : AppColors.warning),
                                      ),
                                      child: Text(
                                        report.resolved ? 'REVIEWED' : 'PENDING',
                                        style: TextStyle(
                                          color: report.resolved ? AppColors.neon : AppColors.warning,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(report.reason, style: const TextStyle(fontSize: 13)),
                                const SizedBox(height: 6),
                                Text(
                                  DateFormat('MMM d, yyyy • h:mm a').format(report.reportedAt),
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
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