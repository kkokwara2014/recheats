import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../menu/domain/food_option.dart';
import '../domain/cart_line_item.dart';
import '../domain/cart_state.dart';

final cartProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);

class CartNotifier extends Notifier<CartState> {
  int _nextId = 0;

  @override
  CartState build() => const CartState();

  /// Adds a configured meal to the cart.
  void addItem({
    required String foodItemId,
    required String name,
    required double unitPrice,
    required int quantity,
    String? imageAsset,
    String? imageUrl,
    List<String> variationLabels = const [],
    Map<String, String> variationSelections = const {},
    List<FoodOption> addOns = const [],
    String specialInstructions = '',
  }) {
    if (quantity < 1) return;

    final line = CartLineItem(
      id: 'cart-${_nextId++}',
      foodItemId: foodItemId,
      name: name,
      unitPrice: unitPrice,
      quantity: quantity,
      imageAsset: imageAsset,
      imageUrl: imageUrl,
      variationLabels: List.unmodifiable(variationLabels),
      variationSelections: Map.unmodifiable(variationSelections),
      addOns: List.unmodifiable(addOns),
      specialInstructions: specialInstructions.trim(),
    );

    state = state.copyWith(lines: [...state.lines, line]);
  }

  /// Replaces an existing line after the customer modifies it.
  void replaceLine({
    required String lineId,
    required String foodItemId,
    required String name,
    required double unitPrice,
    required int quantity,
    String? imageAsset,
    String? imageUrl,
    List<String> variationLabels = const [],
    Map<String, String> variationSelections = const {},
    List<FoodOption> addOns = const [],
    String specialInstructions = '',
  }) {
    if (quantity < 1) {
      removeLine(lineId);
      return;
    }

    final existing = state.lineById(lineId);
    if (existing == null) {
      addItem(
        foodItemId: foodItemId,
        name: name,
        unitPrice: unitPrice,
        quantity: quantity,
        imageAsset: imageAsset,
        imageUrl: imageUrl,
        variationLabels: variationLabels,
        variationSelections: variationSelections,
        addOns: addOns,
        specialInstructions: specialInstructions,
      );
      return;
    }

    final updated = CartLineItem(
      id: lineId,
      foodItemId: foodItemId,
      name: name,
      unitPrice: unitPrice,
      quantity: quantity,
      imageAsset: imageAsset,
      imageUrl: imageUrl,
      variationLabels: List.unmodifiable(variationLabels),
      variationSelections: Map.unmodifiable(variationSelections),
      addOns: List.unmodifiable(addOns),
      specialInstructions: specialInstructions.trim(),
    );

    state = state.copyWith(
      lines: [
        for (final line in state.lines)
          if (line.id == lineId) updated else line,
      ],
    );
  }

  void setQuantity(String lineId, int quantity) {
    if (quantity < 1) {
      removeLine(lineId);
      return;
    }
    state = state.copyWith(
      lines: [
        for (final line in state.lines)
          if (line.id == lineId) line.copyWith(quantity: quantity) else line,
      ],
    );
  }

  void updateSpecialInstructions(String lineId, String instructions) {
    state = state.copyWith(
      lines: [
        for (final line in state.lines)
          if (line.id == lineId)
            line.copyWith(specialInstructions: instructions.trim())
          else
            line,
      ],
    );
  }

  void removeLine(String lineId) {
    state = state.copyWith(
      lines: state.lines.where((line) => line.id != lineId).toList(),
    );
  }

  void clear() => state = const CartState();
}
