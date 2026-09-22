// path: lib/screens/vendor/vendor_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_dialogs.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vendor_provider.dart';
import '../../widgets/alien_avatar.dart';

class VendorHomeScreen extends StatefulWidget {
  const VendorHomeScreen({super.key});

  @override
  State<VendorHomeScreen> createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends State<VendorHomeScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    context.read<VendorProvider>().loadMyVendor().then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final vendorProvider = context.watch<VendorProvider>();
    final isLive = vendorProvider.isMyVendorLive;
    final myVendor = vendorProvider.myVendor;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.neon)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Dashboard'),
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              AlienAvatar(size: 52, glow: true, imageUrl: myVendor?.avatarUrl),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Welcome back,', style: TextStyle(color: AppColors.textSecondary)),
                  Text(auth.currentUser?.name ?? myVendor?.name ?? 'Vendor',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('LIVE STATUS',
              style: TextStyle(
                  color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isLive ? AppColors.neon : AppColors.border, width: isLive ? 1.4 : 1),
              boxShadow: isLive ? AppShadows.neonGlow(opacity: 0.18) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AlienAvatar(size: 40, imageUrl: myVendor?.avatarUrl),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('You are',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        Text(
                          isLive ? 'LIVE •' : 'OFFLINE',
                          style: TextStyle(
                            color: isLive ? AppColors.neon : AppColors.textMuted,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLive ? AppColors.danger : AppColors.neon,
                      foregroundColor: isLive ? Colors.white : Colors.black,
                    ),
                    onPressed: () => _confirmToggle(context, vendorProvider, isLive),
                    child: Text(isLive ? 'STOP SHARING LOCATION' : 'GO LIVE'),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isLive
                      ? 'Your location is currently visible to E.A.T. customers.'
                      : 'Go live to appear on the map for nearby customers.',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                if (vendorProvider.error != null) ...[
                  const SizedBox(height: 8),
                  Text(vendorProvider.error!,
                      style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (myVendor != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(myVendor.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(myVendor.subCategory,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _confirmToggle(BuildContext context, VendorProvider provider, bool isLive) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(isLive ? 'Stop sharing location?' : 'Go live?'),
        content: Text(
          isLive
              ? 'Customers will no longer be able to see you on the live map.'
              : 'Your real-time GPS location will be visible to nearby customers on the live map until you stop sharing.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await provider.setMyVendorLive(!isLive);
              if (!ok && context.mounted && provider.error != null) {
                await AppDialogs.showMessage(context, provider.error!, isError: true);
              }
            },
            child: Text(isLive ? 'STOP SHARING' : 'GO LIVE'),
          ),
        ],
      ),
    );
  }
}