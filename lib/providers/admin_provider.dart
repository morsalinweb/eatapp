// path: lib/providers/admin_provider.dart
import 'package:flutter/material.dart';
import '../core/utils/category_mapper.dart';
import '../models/models.dart';
import '../services/api_client.dart';

/// Lightweight summary of a `vendors` admin-listing row, used by the
/// Manage Vendors screen. Kept separate from the shared [Vendor] model
/// since this listing carries admin-only fields (owner email/name,
/// suspension flag) that the rest of the app doesn't need.
class AdminVendorSummary {
  final String id;
  final String name;
  final VendorCategory category;
  final VendorStatus status;
  final bool isLive;
  final bool isSuspended;
  final String ownerId;
  final String ownerEmail;
  final String ownerName;

  AdminVendorSummary({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
    required this.isLive,
    required this.isSuspended,
    required this.ownerId,
    required this.ownerEmail,
    required this.ownerName,
  });

  factory AdminVendorSummary.fromJson(Map<String, dynamic> json) {
    final locations = json['vendor_locations'];
    Map<String, dynamic>? locationRow;
    if (locations is List && locations.isNotEmpty) {
      locationRow = locations.first as Map<String, dynamic>;
    } else if (locations is Map<String, dynamic>) {
      locationRow = locations;
    }
    final owner = json['owner'] as Map?;
    return AdminVendorSummary(
      id: json['id'],
      name: json['name'] ?? '',
      category: CategoryMapper.fromApi(json['category']),
      status: vendorStatusFromApi(json['status']),
      isLive: locationRow?['is_live'] ?? false,
      isSuspended: json['is_suspended'] ?? false,
      ownerId: json['owner_id'] ?? '',
      ownerEmail: owner?['email'] ?? '',
      ownerName: owner?['full_name'] ?? '',
    );
  }
}

/// A single point on the admin "Live Locations" map — either a currently
/// live vendor, or a customer's most recently recorded position. There is
/// no history here: each point is just the latest known location.
class AdminLocationPoint {
  final String id;
  final String name;
  final String role; // 'vendor' or 'customer'
  final String? category;
  final String? avatarUrl;
  final double lat;
  final double lng;
  final DateTime? lastUpdatedAt;

  AdminLocationPoint({
    required this.id,
    required this.name,
    required this.role,
    this.category,
    this.avatarUrl,
    required this.lat,
    required this.lng,
    this.lastUpdatedAt,
  });

  bool get isVendor => role == 'vendor';

  factory AdminLocationPoint.fromJson(Map<String, dynamic> json) => AdminLocationPoint(
        id: json['id'] ?? '',
        name: json['name'] ?? 'Unknown',
        role: json['role'] ?? 'customer',
        category: json['category'],
        avatarUrl: json['avatar_url'],
        lat: (json['lat'] as num?)?.toDouble() ?? 0,
        lng: (json['lng'] as num?)?.toDouble() ?? 0,
        lastUpdatedAt:
            json['last_updated_at'] != null ? DateTime.tryParse(json['last_updated_at']) : null,
      );
}

class AdminProvider extends ChangeNotifier {
  List<VendorApplication> applications = [];
  List<VendorReport> reports = [];
  List<AppUser> users = [];
  List<AdminVendorSummary> vendorsAdmin = [];
  List<AdminLocationPoint> locations = [];

  int totalUsers = 0;
  int totalVendors = 0;
  int pendingApplications = 0;
  int liveVendorsNow = 0;
  int openReports = 0;
  int suspendedAccounts = 0;

  bool loading = false;
  String? error;

  Future<void> loadStats() async {
    try {
      final json = await ApiClient.instance.get('/admin/stats');
      totalUsers = json['total_users'] ?? 0;
      totalVendors = json['total_vendors'] ?? 0;
      pendingApplications = json['pending_applications'] ?? 0;
      liveVendorsNow = json['live_vendors_now'] ?? 0;
      openReports = json['open_reports'] ?? 0;
      suspendedAccounts = json['suspended_accounts'] ?? 0;
      notifyListeners();
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
    }
  }

  Future<void> loadApplications() async {
    loading = true;
    notifyListeners();
    try {
      final json = await ApiClient.instance.get('/admin/applications');
      applications = (json['applications'] as List).map((a) => VendorApplication.fromJson(a)).toList();
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadReports() async {
    loading = true;
    notifyListeners();
    try {
      final json = await ApiClient.instance.get('/admin/reports');
      reports = (json['reports'] as List).map((r) => VendorReport.fromJson(r)).toList();
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadUsers({String? role, String? query}) async {
    loading = true;
    notifyListeners();
    try {
      final json = await ApiClient.instance.get('/admin/users', query: {
        if (role != null) 'role': role,
        if (query != null && query.isNotEmpty) 'q': query,
      });
      users = (json['users'] as List).map((u) => AppUser.fromJson(u)).toList();
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadVendorsAdmin({String? status}) async {
    loading = true;
    notifyListeners();
    try {
      final json = await ApiClient.instance.get('/admin/vendors', query: {
        if (status != null) 'status': status,
      });
      vendorsAdmin = (json['vendors'] as List).map((v) => AdminVendorSummary.fromJson(v)).toList();
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadLocations() async {
    loading = true;
    notifyListeners();
    try {
      final json = await ApiClient.instance.get('/admin/locations');
      locations = (json['locations'] as List).map((l) => AdminLocationPoint.fromJson(l)).toList();
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> approve(VendorApplication app) async {
    try {
      await ApiClient.instance.post('/admin/applications/${app.id}/approve');
      app.status = VendorStatus.approved;
      totalVendors += 1;
      pendingApplications = (pendingApplications - 1).clamp(0, 1 << 30);
      notifyListeners();
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
    }
  }

  Future<void> reject(VendorApplication app, {String? reason}) async {
    try {
      await ApiClient.instance.post('/admin/applications/${app.id}/reject', body: {
        if (reason != null) 'reason': reason,
      });
      app.status = VendorStatus.rejected;
      pendingApplications = (pendingApplications - 1).clamp(0, 1 << 30);
      notifyListeners();
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
    }
  }

  Future<void> resolveReport(VendorReport report) async {
    try {
      await ApiClient.instance.post('/admin/reports/${report.id}/resolve', body: {'action': 'resolved'});
      report.resolved = true;
      openReports = (openReports - 1).clamp(0, 1 << 30);
      notifyListeners();
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
    }
  }

  Future<bool> suspendUser(String userId, {String? reason}) async {
    try {
      await ApiClient.instance.post('/admin/users/$userId/suspend', body: {
        if (reason != null) 'reason': reason,
      });
      _markUserSuspended(userId, true);
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> reinstateUser(String userId) async {
    try {
      await ApiClient.instance.post('/admin/users/$userId/reinstate');
      _markUserSuspended(userId, false);
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    }
  }

  void _markUserSuspended(String userId, bool suspended) {
    final uIdx = users.indexWhere((u) => u.id == userId);
    if (uIdx != -1) {
      final u = users[uIdx];
      users[uIdx] = AppUser(
        id: u.id,
        name: u.name,
        email: u.email,
        phone: u.phone,
        role: u.role,
        avatarUrl: u.avatarUrl,
        isSuspended: suspended,
      );
    }

    final vIdx = vendorsAdmin.indexWhere((v) => v.ownerId == userId);
    if (vIdx != -1) {
      final v = vendorsAdmin[vIdx];
      vendorsAdmin[vIdx] = AdminVendorSummary(
        id: v.id,
        name: v.name,
        category: v.category,
        status: v.status,
        isLive: suspended ? false : v.isLive,
        isSuspended: suspended,
        ownerId: v.ownerId,
        ownerEmail: v.ownerEmail,
        ownerName: v.ownerName,
      );
    }

    for (final report in reports) {
      if (report.vendorOwnerId == userId) {
        report.vendorSuspended = suspended;
      }
    }

    notifyListeners();
  }
}