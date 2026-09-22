// path: lib/widgets/category_filter_bar.dart
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/models.dart';

class CategoryFilterBar extends StatelessWidget {
  final VendorCategory? selected;
  final ValueChanged<VendorCategory?> onSelect;

  const CategoryFilterBar({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  static const _icons = {
    null: Icons.apps_rounded,
    VendorCategory.tacos: Icons.local_fire_department_outlined,
    VendorCategory.tamales: Icons.ramen_dining_outlined,
    VendorCategory.iceCream: Icons.icecream_outlined,
    VendorCategory.bbq: Icons.outdoor_grill_outlined,
    VendorCategory.foodTruck: Icons.local_shipping_outlined,
    VendorCategory.dessert: Icons.cake_outlined,
    VendorCategory.drinks: Icons.local_cafe_outlined,
    VendorCategory.more: Icons.more_horiz_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final items = <VendorCategory?>[null, ...VendorCategory.values];
    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final cat = items[i];
          final isSelected = selected == cat;
          final label = cat?.label ?? 'All';
          return GestureDetector(
            onTap: () => onSelect(cat),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.neon : AppColors.surfaceRaised,
                    border: Border.all(
                      color: isSelected ? AppColors.neon : AppColors.border,
                    ),
                    boxShadow: isSelected
                        ? AppShadows.neonGlow(opacity: 0.35, blur: 14)
                        : null,
                  ),
                  child: Icon(
                    _icons[cat],
                    color: isSelected ? Colors.black : AppColors.textSecondary,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isSelected
                        ? AppColors.neon
                        : AppColors.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
