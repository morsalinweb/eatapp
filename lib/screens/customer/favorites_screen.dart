// path: lib/screens/customer/favorites_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/chat_provider.dart';
import '../../providers/vendor_provider.dart';
import '../../widgets/vendor_card.dart';
import '../chat/chat_thread_screen.dart';
import 'vendor_profile_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    context.read<VendorProvider>().loadFavorites().then((_) {
      if (mounted) setState(() => _loading = false);
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
    final favorites = vendorProvider.favoriteVendors;

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.neon))
          : favorites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.favorite_border, size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      const Text('No favorites yet', style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      const Text('Tap the heart on any vendor to save them here.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: favorites.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final vendor = favorites[i];
                    return VendorCard(
                      vendor: vendor,
                      isFavorite: true,
                      onFavorite: () => vendorProvider.toggleFavorite(vendor.id),
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => VendorProfileScreen(vendor: vendor))),
                      onMessage: () => _openChat(vendor),
                    );
                  },
                ),
    );
  }
}