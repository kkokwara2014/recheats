import 'food_option.dart';

/// A named set of mutually exclusive choices (e.g. "Protein options").
class FoodVariationGroup {
  const FoodVariationGroup({
    required this.id,
    required this.name,
    required this.options,
    this.required = false,
  });

  final String id;
  final String name;
  final List<FoodOption> options;

  /// When true, the customer must pick one option before adding.
  final bool required;

  FoodVariationGroup copyWith({
    String? name,
    List<FoodOption>? options,
    bool? required,
  }) {
    return FoodVariationGroup(
      id: id,
      name: name ?? this.name,
      options: options ?? this.options,
      required: required ?? this.required,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'required': required,
        'options': options.map((o) => o.toMap()).toList(),
      };

  factory FoodVariationGroup.fromMap(Map<String, dynamic> map) {
    final rawOptions = map['options'];
    final options = <FoodOption>[];
    if (rawOptions is List) {
      for (final entry in rawOptions) {
        if (entry is Map<String, dynamic>) {
          options.add(FoodOption.fromMap(entry));
        } else if (entry is Map) {
          options.add(FoodOption.fromMap(Map<String, dynamic>.from(entry)));
        }
      }
    }

    return FoodVariationGroup(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      required: map['required'] as bool? ?? false,
      options: options,
    );
  }
}
