import '../../cart/domain/cart_line_item.dart';
import '../../checkout/domain/delivery_details.dart';
import '../../checkout/domain/order_timing.dart';
import '../../shop/domain/fulfillment_method.dart';

/// A recorded customer order. MVP stores fulfillment only — no rider assignment.
class PlacedOrder {
  const PlacedOrder({
    required this.id,
    required this.lines,
    required this.method,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.createdAt,
    this.userId,
    this.pickupLocation,
    this.delivery,
    this.timing = const OrderTiming(),
    this.status = OrderStatus.recorded,
  });

  final String id;
  final String? userId;
  final List<CartLineItem> lines;
  final FulfillmentMethod method;
  final String? pickupLocation;
  final DeliveryDetails? delivery;
  final OrderTiming timing;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final DateTime createdAt;
  final OrderStatus status;

  bool get isPickup => method == FulfillmentMethod.pickup;

  bool get isDelivery => method == FulfillmentMethod.delivery;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'method': method.name,
        if (pickupLocation != null) 'pickupLocation': pickupLocation,
        if (delivery != null) 'delivery': delivery!.toMap(),
        'timing': timing.toMap(),
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'total': total,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'lines': lines
            .map(
              (line) => {
                'id': line.id,
                'foodItemId': line.foodItemId,
                'name': line.name,
                'unitPrice': line.unitPrice,
                'quantity': line.quantity,
                'lineTotal': line.lineTotal,
                if (line.variationLabels.isNotEmpty)
                  'variationLabels': line.variationLabels,
                if (line.specialInstructions.isNotEmpty)
                  'specialInstructions': line.specialInstructions,
              },
            )
            .toList(),
      };
}

enum OrderStatus {
  /// Captured in-app; Rechael fulfills manually (self / third-party / arrange).
  recorded,
  preparing,
  ready,
  completed,
  cancelled,
}
