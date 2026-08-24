/// A priced choice used by variations or add-ons (e.g. Chicken +$5).
class FoodOption {
  const FoodOption({
    required this.id,
    required this.name,
    this.priceDelta = 0,
  });

  final String id;
  final String name;

  /// Extra cost added on top of the base item price.
  final double priceDelta;

  String get formattedDelta {
    if (priceDelta == 0) return '';
    final sign = priceDelta > 0 ? '+' : '-';
    return '$sign\$${priceDelta.abs().toStringAsFixed(2)}';
  }

  String get labelWithPrice {
    final delta = formattedDelta;
    return delta.isEmpty ? name : '$name $delta';
  }

  FoodOption copyWith({
    String? name,
    double? priceDelta,
  }) {
    return FoodOption(
      id: id,
      name: name ?? this.name,
      priceDelta: priceDelta ?? this.priceDelta,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'priceDelta': priceDelta,
      };

  factory FoodOption.fromMap(Map<String, dynamic> map) {
    return FoodOption(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      priceDelta: (map['priceDelta'] as num?)?.toDouble() ?? 0,
    );
  }
}
