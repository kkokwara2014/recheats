import 'cart_line_item.dart';

/// Flat delivery fee applied when the cart has at least one item.
const double kCartDeliveryFee = 5;

/// In-memory cart snapshot for the current session.
class CartState {
  const CartState({this.lines = const []});

  final List<CartLineItem> lines;

  int get itemCount =>
      lines.fold<int>(0, (sum, line) => sum + line.quantity);

  double get subtotal =>
      lines.fold<double>(0, (sum, line) => sum + line.lineTotal);

  double get deliveryFee => isEmpty ? 0 : kCartDeliveryFee;

  double get total => subtotal + deliveryFee;

  String get formattedSubtotal => '\$${subtotal.toStringAsFixed(2)}';

  String get formattedDeliveryFee => '\$${deliveryFee.toStringAsFixed(2)}';

  String get formattedTotal => '\$${total.toStringAsFixed(2)}';

  bool get isEmpty => lines.isEmpty;

  CartLineItem? lineById(String lineId) {
    for (final line in lines) {
      if (line.id == lineId) return line;
    }
    return null;
  }

  CartState copyWith({List<CartLineItem>? lines}) {
    return CartState(lines: lines ?? this.lines);
  }
}
