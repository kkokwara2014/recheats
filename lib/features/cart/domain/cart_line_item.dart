import '../../menu/domain/food_option.dart';

/// One configurable line in the customer cart.
class CartLineItem {
  const CartLineItem({
    required this.id,
    required this.foodItemId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    this.imageAsset,
    this.imageUrl,
    this.variationLabels = const [],
    this.variationSelections = const {},
    this.addOns = const [],
    this.specialInstructions = '',
  });

  /// Stable line id (not the menu item id — same dish can appear twice).
  final String id;
  final String foodItemId;
  final String name;
  final double unitPrice;
  final int quantity;
  final String? imageAsset;
  final String? imageUrl;

  /// Human-readable variation choices (e.g. "Protein: Chicken").
  final List<String> variationLabels;

  /// groupId → selected option id (used when editing a line).
  final Map<String, String> variationSelections;

  /// Selected add-ons with their price deltas.
  final List<FoodOption> addOns;

  final String specialInstructions;

  double get lineTotal => unitPrice * quantity;

  String get formattedLineTotal => '\$${lineTotal.toStringAsFixed(2)}';

  String get formattedUnitPrice => '\$${unitPrice.toStringAsFixed(2)}';

  bool get hasNotes => specialInstructions.trim().isNotEmpty;

  bool get hasDetails =>
      variationLabels.isNotEmpty || addOns.isNotEmpty || hasNotes;

  CartLineItem copyWith({
    String? name,
    double? unitPrice,
    int? quantity,
    String? imageAsset,
    String? imageUrl,
    List<String>? variationLabels,
    Map<String, String>? variationSelections,
    List<FoodOption>? addOns,
    String? specialInstructions,
  }) {
    return CartLineItem(
      id: id,
      foodItemId: foodItemId,
      name: name ?? this.name,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      imageAsset: imageAsset ?? this.imageAsset,
      imageUrl: imageUrl ?? this.imageUrl,
      variationLabels: variationLabels ?? this.variationLabels,
      variationSelections: variationSelections ?? this.variationSelections,
      addOns: addOns ?? this.addOns,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }

  /// Rebuilds a line from an order document (subset of cart fields).
  factory CartLineItem.fromOrderMap(Map<String, dynamic> map) {
    final labelsRaw = map['variationLabels'];
    final labels = <String>[];
    if (labelsRaw is List) {
      for (final entry in labelsRaw) {
        if (entry is String) labels.add(entry);
      }
    }
    return CartLineItem(
      id: map['id'] as String? ?? '',
      foodItemId: map['foodItemId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      variationLabels: List.unmodifiable(labels),
      specialInstructions: map['specialInstructions'] as String? ?? '',
    );
  }
}
