import 'food_option.dart';
import 'food_variation_group.dart';
import 'menu_category.dart';

/// A single menu item in Rechael's digital restaurant catalog.
class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.isAvailable = true,
    this.preparationMinutes = 20,
    this.isSpecial = false,
    this.isPopular = false,
    this.imageAsset,
    this.imageUrl,
    this.portionSize,
    this.ingredients = const [],
    this.allergens = const [],
    this.variationGroups = const [],
    this.addOns = const [],
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final MenuCategory category;

  /// Soft availability — unavailable items stay on the menu, hidden from order.
  final bool isAvailable;

  /// Typical kitchen prep time in minutes.
  final int preparationMinutes;

  final bool isSpecial;
  final bool isPopular;

  /// Optional local asset; preferred over [imageUrl] when both are set.
  final String? imageAsset;

  /// Network image (Firebase Storage or CDN).
  final String? imageUrl;

  /// Human-readable serving size (e.g. "Regular plate · serves 1").
  final String? portionSize;

  /// Key ingredients shown on the detail screen when present.
  final List<String> ingredients;

  /// Allergen labels shown when present (e.g. "Fish", "Gluten").
  final List<String> allergens;

  /// Optional mutually exclusive choice groups (e.g. protein options).
  final List<FoodVariationGroup> variationGroups;

  /// Optional extras the customer can stack (select many).
  final List<FoodOption> addOns;

  String get formattedPrice => '\$${price.toStringAsFixed(2)}';

  String get preparationLabel {
    if (preparationMinutes <= 0) return '';
    return '$preparationMinutes min';
  }

  bool get hasCustomizations =>
      variationGroups.isNotEmpty || addOns.isNotEmpty;

  bool get hasIngredientsOrAllergens =>
      ingredients.isNotEmpty || allergens.isNotEmpty;

  FoodItem copyWith({
    String? name,
    String? description,
    double? price,
    MenuCategory? category,
    bool? isAvailable,
    int? preparationMinutes,
    bool? isSpecial,
    bool? isPopular,
    String? imageAsset,
    bool clearImageAsset = false,
    String? imageUrl,
    bool clearImageUrl = false,
    String? portionSize,
    bool clearPortionSize = false,
    List<String>? ingredients,
    List<String>? allergens,
    List<FoodVariationGroup>? variationGroups,
    List<FoodOption>? addOns,
  }) {
    return FoodItem(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
      preparationMinutes: preparationMinutes ?? this.preparationMinutes,
      isSpecial: isSpecial ?? this.isSpecial,
      isPopular: isPopular ?? this.isPopular,
      imageAsset: clearImageAsset ? null : (imageAsset ?? this.imageAsset),
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
      portionSize:
          clearPortionSize ? null : (portionSize ?? this.portionSize),
      ingredients: ingredients ?? this.ingredients,
      allergens: allergens ?? this.allergens,
      variationGroups: variationGroups ?? this.variationGroups,
      addOns: addOns ?? this.addOns,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'category': category.id,
        'isAvailable': isAvailable,
        'preparationMinutes': preparationMinutes,
        'isSpecial': isSpecial,
        'isPopular': isPopular,
        if (imageAsset != null && imageAsset!.isNotEmpty)
          'imageAsset': imageAsset,
        if (imageUrl != null && imageUrl!.isNotEmpty) 'imageUrl': imageUrl,
        if (portionSize != null && portionSize!.isNotEmpty)
          'portionSize': portionSize,
        'ingredients': ingredients,
        'allergens': allergens,
        'variationGroups': variationGroups.map((g) => g.toMap()).toList(),
        'addOns': addOns.map((o) => o.toMap()).toList(),
      };

  factory FoodItem.fromMap(Map<String, dynamic> map, {String? id}) {
    final categoryId = map['category'] as String? ?? MenuCategory.rice.id;
    final category =
        MenuCategory.fromId(categoryId) ?? MenuCategory.rice;

    final rawGroups = map['variationGroups'];
    final groups = <FoodVariationGroup>[];
    if (rawGroups is List) {
      for (final entry in rawGroups) {
        if (entry is Map<String, dynamic>) {
          groups.add(FoodVariationGroup.fromMap(entry));
        } else if (entry is Map) {
          groups.add(
            FoodVariationGroup.fromMap(Map<String, dynamic>.from(entry)),
          );
        }
      }
    }

    final rawAddOns = map['addOns'];
    final addOns = <FoodOption>[];
    if (rawAddOns is List) {
      for (final entry in rawAddOns) {
        if (entry is Map<String, dynamic>) {
          addOns.add(FoodOption.fromMap(entry));
        } else if (entry is Map) {
          addOns.add(FoodOption.fromMap(Map<String, dynamic>.from(entry)));
        }
      }
    }

    return FoodItem(
      id: id ?? map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      category: category,
      isAvailable: map['isAvailable'] as bool? ?? true,
      preparationMinutes: (map['preparationMinutes'] as num?)?.toInt() ?? 20,
      isSpecial: map['isSpecial'] as bool? ?? false,
      isPopular: map['isPopular'] as bool? ?? false,
      imageAsset: map['imageAsset'] as String?,
      imageUrl: map['imageUrl'] as String?,
      portionSize: map['portionSize'] as String?,
      ingredients: _stringList(map['ingredients']),
      allergens: _stringList(map['allergens']),
      variationGroups: groups,
      addOns: addOns,
    );
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => e?.toString().trim() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }
}
