// path: lib/widgets/vendor_card.dart
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/models.dart';
import 'alien_avatar.dart';
import 'live_badge.dart';

class VendorCard extends StatelessWidget {
  final Vendor vendor;
  final VoidCallback onTap;
  final VoidCallback onMessage;
  final VoidCallback onFavorite;
  final bool isFavorite;

  const VendorCard({
    super.key,
    required this.vendor,
    required this.onTap,
    required this.onMessage,
    required this.onFavorite,
    required this.isFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: vendor.isLive ? AppShadows.neonGlow(opacity: 0.12) : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AlienAvatar(size: 56, glow: vendor.isLive, imageUrl: vendor.avatarUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          vendor.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (vendor.isLive) const LiveBadge(),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    vendor.subCategory,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${vendor.distanceMiles.toStringAsFixed(1)} mi away'
                    '${vendor.isLive ? " • Open" : " • Offline"}',
                    style: TextStyle(
                      color: vendor.isLive
                          ? AppColors.neon
                          : AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onTap,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            minimumSize: const Size(0, 36),
                          ),
                          child: const Text('View Profile',
                              style: TextStyle(fontSize: 12.5)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onMessage,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            minimumSize: const Size(0, 36),
                          ),
                          child: const Text('Message',
                              style: TextStyle(fontSize: 12.5)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onFavorite,
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? AppColors.neon : AppColors.textMuted,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}