// path: lib/models/models.dart
import '../core/utils/category_mapper.dart';

/// Field names/types here are chosen to parse directly from eat_backend's
/// JSON responses (see eat_backend/README.md for the endpoint reference).

enum UserRole { customer, vendor, admin }

UserRole userRoleFromApi(String? value) {
  switch (value) {
    case 'vendor':
      return UserRole.vendor;
    case 'admin':
      return UserRole.admin;
    default:
      return UserRole.customer;
  }
}

String userRoleToApi(UserRole role) => role.name;

enum VendorStatus { pending, approved, rejected, suspended }

VendorStatus vendorStatusFromApi(String? value) {
  switch (value) {
    case 'approved':
      return VendorStatus.approved;
    case 'rejected':
      return VendorStatus.rejected;
    case 'suspended':
      return VendorStatus.suspended;
    default:
      return VendorStatus.pending;
  }
}

enum VendorCategory { tacos, tamales, iceCream, bbq, foodTruck, dessert, drinks, more }

extension VendorCategoryX on VendorCategory {
  String get label {
    switch (this) {
      case VendorCategory.tacos:
        return 'Tacos';
      case VendorCategory.tamales:
        return 'Tamales';
      case VendorCategory.iceCream:
        return 'Ice Cream';
      case VendorCategory.bbq:
        return 'BBQ';
      case VendorCategory.foodTruck:
        return 'Food Truck';
      case VendorCategory.dessert:
        return 'Dessert';
      case VendorCategory.drinks:
        return 'Drinks';
      case VendorCategory.more:
        return 'More';
    }
  }
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final UserRole role;
  final String? avatarUrl;
  final bool isSuspended;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.avatarUrl,
    this.isSuspended = false,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'],
        name: json['full_name'] ?? '',
        email: json['email'] ?? '',
        phone: json['phone'],
        role: userRoleFromApi(json['role']),
        avatarUrl: json['avatar_url'],
        isSuspended: json['is_suspended'] ?? false,
      );
}

class Vendor {
  final String id;
  final String ownerUserId;
  final String name;
  final VendorCategory category;
  final String subCategory;
  final String description;
  final String? coverImageUrl;
  final String? avatarUrl;
  final double rating;
  final int ratingCount;
  final String priceTier;
  final String operatingHours;
  final String serviceAreaMiles;
  final String? instagramHandle;
  final String? website;
  final bool cashOnly;
  final VendorStatus status;

  bool isLive;
  double? lat;
  double? lng;
  DateTime? liveSince;
  double distanceMiles;

  Vendor({
    required this.id,
    required this.ownerUserId,
    required this.name,
    required this.category,
    required this.subCategory,
    required this.description,
    this.coverImageUrl,
    this.avatarUrl,
    this.rating = 0,
    this.ratingCount = 0,
    this.priceTier = '\$',
    this.operatingHours = '',
    this.serviceAreaMiles = '',
    this.instagramHandle,
    this.website,
    this.cashOnly = false,
    this.status = VendorStatus.approved,
    this.isLive = false,
    this.lat,
    this.lng,
    this.liveSince,
    this.distanceMiles = 0,
  });

  /// Parses the shape returned by the nearby_live_vendors() RPC
  /// (GET /vendors?lat=&lng=), which is flatter than the full vendor row.
  factory Vendor.fromNearbyJson(Map<String, dynamic> json) => Vendor(
        id: json['vendor_id'],
        ownerUserId: '',
        name: json['name'] ?? '',
        category: CategoryMapper.fromApi(json['category']),
        subCategory: json['sub_category'] ?? '',
        description: '',
        avatarUrl: json['avatar_url'],
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        ratingCount: json['rating_count'] ?? 0,
        priceTier: json['price_tier'] ?? '\$',
        isLive: true,
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        liveSince: json['live_since'] != null ? DateTime.tryParse(json['live_since']) : null,
        distanceMiles: ((json['distance_meters'] as num?)?.toDouble() ?? 0) / 1609.34,
      );

  /// Parses the full `vendors` row shape (GET /vendors/:id, /vendors/me/profile,
  /// admin listings, favorites) which nests `vendor_locations`.
  factory Vendor.fromJson(Map<String, dynamic> json) {
    final locations = json['vendor_locations'];
    Map<String, dynamic>? locationRow;
    if (locations is List && locations.isNotEmpty) {
      locationRow = locations.first as Map<String, dynamic>;
    } else if (locations is Map<String, dynamic>) {
      locationRow = locations;
    }

    return Vendor(
      id: json['id'],
      ownerUserId: json['owner_id'] ?? '',
      name: json['name'] ?? '',
      category: CategoryMapper.fromApi(json['category']),
      subCategory: json['sub_category'] ?? '',
      description: json['description'] ?? '',
      coverImageUrl: json['cover_image_url'],
      avatarUrl: json['avatar_url'],
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      ratingCount: json['rating_count'] ?? 0,
      priceTier: json['price_tier'] ?? '\$',
      operatingHours: json['operating_hours'] ?? '',
      serviceAreaMiles:
          json['service_area_miles'] != null ? '${json['service_area_miles']} Miles' : '',
      instagramHandle: json['instagram_handle'],
      website: json['website'],
      cashOnly: json['cash_only'] ?? false,
      status: vendorStatusFromApi(json['status']),
      isLive: locationRow?['is_live'] ?? false,
      liveSince:
          locationRow?['live_since'] != null ? DateTime.tryParse(locationRow!['live_since']) : null,
    );
  }

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'sub_category': subCategory,
        'description': description,
        'operating_hours': operatingHours,
        'instagram_handle': instagramHandle,
        'website': website,
        'cash_only': cashOnly,
      };
}

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime sentAt;
  final bool isMine;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.sentAt,
    required this.isMine,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, String myUserId) => ChatMessage(
        id: json['id'],
        senderId: json['sender_id'],
        text: json['body'] ?? '',
        sentAt: DateTime.tryParse(json['sent_at'] ?? '') ?? DateTime.now(),
        isMine: json['sender_id'] == myUserId,
      );
}

class ChatThread {
  final String id;
  final String vendorId;
  final String otherPartyName;
  final String otherPartyAvatarUrl;
  List<ChatMessage> messages;
  int unreadCount;

  ChatThread({
    required this.id,
    required this.vendorId,
    required this.otherPartyName,
    required this.otherPartyAvatarUrl,
    List<ChatMessage>? messages,
    this.unreadCount = 0,
  }) : messages = messages ?? [];

  /// Parses a row from GET /threads, which nests both `customer` and
  /// `vendor` — pick whichever side isn't "me".
  factory ChatThread.fromJson(Map<String, dynamic> json, {required bool viewerIsVendor}) {
    final other = viewerIsVendor ? json['customer'] : json['vendor'];
    final last = json['last_message'];
    return ChatThread(
      id: json['id'],
      vendorId: (json['vendor'] as Map?)?['id'] ?? '',
      otherPartyName: other?['full_name'] ?? other?['name'] ?? 'Unknown',
      otherPartyAvatarUrl: other?['avatar_url'] ?? '',
      unreadCount: json['unread_count'] ?? 0,
      messages: last != null
          ? [
              ChatMessage(
                id: 'preview',
                senderId: last['sender_id'] ?? '',
                text: last['body'] ?? '',
                sentAt: DateTime.tryParse(last['sent_at'] ?? '') ?? DateTime.now(),
                isMine: false,
              ),
            ]
          : [],
    );
  }

  ChatMessage? get lastMessage => messages.isEmpty ? null : messages.last;
}

class VendorApplication {
  final String id;
  final String applicantName;
  final String email;
  final String businessName;
  final VendorCategory category;
  final String description;
  final DateTime submittedAt;
  VendorStatus status;

  VendorApplication({
    required this.id,
    required this.applicantName,
    required this.email,
    required this.businessName,
    required this.category,
    required this.description,
    required this.submittedAt,
    this.status = VendorStatus.pending,
  });

  factory VendorApplication.fromJson(Map<String, dynamic> json) => VendorApplication(
        id: json['id'],
        applicantName: (json['applicant'] as Map?)?['full_name'] ?? '',
        email: (json['applicant'] as Map?)?['email'] ?? '',
        businessName: json['business_name'] ?? '',
        category: CategoryMapper.fromApi(json['category']),
        description: json['description'] ?? '',
        submittedAt: DateTime.tryParse(json['submitted_at'] ?? '') ?? DateTime.now(),
        status: vendorStatusFromApi(json['status']),
      );
}

class VendorReport {
  final String id;
  final String vendorName;
  final String vendorEmail;
  final String vendorOwnerId;
  final String reporterName;
  final String reason;
  final DateTime reportedAt;
  bool resolved;

  /// Whether the *vendor* behind this report is currently suspended. Kept
  /// mutable (like [resolved]) so AdminProvider can flip it in place right
  /// after a successful suspend/reinstate call, without needing a full
  /// reports reload for the UI to reflect it.
  bool vendorSuspended;

  VendorReport({
    required this.id,
    required this.vendorName,
    this.vendorEmail = '',
    this.vendorOwnerId = '',
    required this.reporterName,
    required this.reason,
    required this.reportedAt,
    this.resolved = false,
    this.vendorSuspended = false,
  });

  factory VendorReport.fromJson(Map<String, dynamic> json) {
    final vendor = json['vendor'] as Map?;
    final owner = vendor?['owner'] as Map?;
    return VendorReport(
      id: json['id'],
      vendorName: vendor?['name'] ?? 'Unknown vendor',
      vendorEmail: owner?['email'] ?? '',
      vendorOwnerId: vendor?['owner_id'] ?? '',
      reporterName: (json['reporter'] as Map?)?['full_name'] ?? 'Anonymous',
      reason: json['reason'] ?? '',
      reportedAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      resolved: json['status'] != 'open',
      vendorSuspended: vendor?['is_suspended'] ?? false,
    );
  }
}