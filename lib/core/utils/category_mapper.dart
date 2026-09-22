// path: lib/core/utils/category_mapper.dart
import '../../models/models.dart';

/// The backend/Postgres enum uses snake_case ('ice_cream', 'food_truck');
/// the Dart enum uses camelCase (iceCream, foodTruck). This is the single
/// place that translation happens.
class CategoryMapper {
  CategoryMapper._();

  static const Map<VendorCategory, String> _toApi = {
    VendorCategory.tacos: 'tacos',
    VendorCategory.tamales: 'tamales',
    VendorCategory.iceCream: 'ice_cream',
    VendorCategory.bbq: 'bbq',
    VendorCategory.foodTruck: 'food_truck',
    VendorCategory.dessert: 'dessert',
    VendorCategory.drinks: 'drinks',
    VendorCategory.more: 'more',
  };

  static String toApi(VendorCategory category) => _toApi[category] ?? 'more';

  static VendorCategory fromApi(String? value) {
    if (value == null) return VendorCategory.more;
    return _toApi.entries
        .firstWhere((e) => e.value == value, orElse: () => const MapEntry(VendorCategory.more, 'more'))
        .key;
  }
}
