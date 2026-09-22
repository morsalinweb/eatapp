// path: lib/screens/customer/nearby_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/chat_provider.dart';
import '../../providers/vendor_provider.dart';
import '../../widgets/category_filter_bar.dart';
import '../../widgets/vendor_card.dart';
import '../chat/chat_thread_screen.dart';
import 'vendor_profile_screen.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vendorProvider = context.read<VendorProvider>();
      if (vendorProvider.allVendors.isEmpty && !vendorProvider.loading) {
        vendorProvider.loadNearbyVendors();
      }
    });
  }

  Future<void> _openChat(Vendor vendor) async {
    final thread = await context
        .read<ChatProvider>()
        .startThreadWithVendor(vendor.id, vendor.name, vendorAvatarUrl: vendor.avatarUrl);
    if (!mounted || thread == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatThreadScreen(threadTitle: vendor.name, thread: thread)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vendorProvider = context.watch<VendorProvider>();
    final vendors = vendorProvider.filteredVendors;

    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Vendors')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              onChanged: vendorProvider.setSearchQuery,
              decoration: const InputDecoration(
                hintText: 'Search vendors...',
                prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
              ),
            ),
          ),
          const SizedBox(height: 12),
          CategoryFilterBar(
            selected: vendorProvider.activeFilter,
            onSelect: vendorProvider.setFilter,
          ),
          const SizedBox(height: 8),
          if (vendorProvider.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.danger, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(vendorProvider.error!,
                        style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                  ),
                  TextButton(
                    onPressed: () => vendorProvider.loadNearbyVendors(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: vendorProvider.loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.neon))
                : vendors.isEmpty
                    ? const Center(
                        child: Text('No vendors match your search',
                            style: TextStyle(color: AppColors.textSecondary)),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: vendors.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final vendor = vendors[i];
                          return VendorCard(
                            vendor: vendor,
                            isFavorite: vendorProvider.isFavorite(vendor.id),
                            onFavorite: () => vendorProvider.toggleFavorite(vendor.id),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => VendorProfileScreen(vendor: vendor)),
                            ),
                            onMessage: () => _openChat(vendor),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}