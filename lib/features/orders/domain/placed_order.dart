import '../../cart/domain/cart_line_item.dart';
import '../../checkout/domain/delivery_details.dart';
import '../../checkout/domain/order_timing.dart';
import '../../payment/domain/order_payment.dart';
import '../../shop/domain/fulfillment_method.dart';

/// A customer order. Payment metadata is Stripe IDs only.
class PlacedOrder {
  const PlacedOrder({
    required this.id,
    required this.displayCode,
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
    this.expectedPrepMinutes = 20,
    this.status = OrderStatus.received,
    this.payment,
  });

  final String id;

  /// Customer-facing order number (e.g. `RE1025`).
  final String displayCode;

  final String? userId;
  final List<CartLineItem> lines;
  final FulfillmentMethod method;
  final String? pickupLocation;
  final DeliveryDetails? delivery;
  final OrderTiming timing;

  /// Typical kitchen prep window in minutes for this order.
  final int expectedPrepMinutes;

  final double subtotal;
  final double deliveryFee;
  final double total;
  final DateTime createdAt;
  final OrderStatus status;
  final OrderPayment? payment;

  bool get isPickup => method == FulfillmentMethod.pickup;

  bool get isDelivery => method == FulfillmentMethod.delivery;

  bool get isCancelled => status == OrderStatus.cancelled;

  String get formattedTotal => '\$${total.toStringAsFixed(2)}';

  String get formattedSubtotal => '\$${subtotal.toStringAsFixed(2)}';

  String get formattedDeliveryFee => '\$${deliveryFee.toStringAsFixed(2)}';

  String get prepTimeLabel {
    if (expectedPrepMinutes <= 0) return '';
    return '~$expectedPrepMinutes min';
  }

  /// Compact line summary for history cards (e.g. "Jollof ×2, Egusi Soup").
  String get itemsSummary {
    if (lines.isEmpty) return '';
    return lines
        .map(
          (line) => line.quantity > 1
              ? '${line.name} ×${line.quantity}'
              : line.name,
        )
        .join(', ');
  }

  /// e.g. "Aug 24, 2026 · 6:30 PM" without needing the intl package.
  String get formattedCreatedAt {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[createdAt.month - 1];
    final hour24 = createdAt.hour;
    final minute = createdAt.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '$month ${createdAt.day}, ${createdAt.year} · $hour12:$minute $period';
  }

  PlacedOrder copyWith({
    OrderStatus? status,
    OrderPayment? payment,
  }) {
    return PlacedOrder(
      id: id,
      displayCode: displayCode,
      userId: userId,
      lines: lines,
      method: method,
      pickupLocation: pickupLocation,
      delivery: delivery,
      timing: timing,
      expectedPrepMinutes: expectedPrepMinutes,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      total: total,
      createdAt: createdAt,
      status: status ?? this.status,
      payment: payment ?? this.payment,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'displayCode': displayCode,
        'method': method.name,
        if (pickupLocation != null) 'pickupLocation': pickupLocation,
        if (delivery != null) 'delivery': delivery!.toMap(),
        'timing': timing.toMap(),
        'expectedPrepMinutes': expectedPrepMinutes,
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'total': total,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        if (payment != null) 'payment': payment!.toMap(),
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

  factory PlacedOrder.fromMap(Map<String, dynamic> map, {required String id}) {
    final methodName = map['method'] as String? ?? FulfillmentMethod.pickup.name;
    final method = FulfillmentMethod.values.firstWhere(
      (value) => value.name == methodName,
      orElse: () => FulfillmentMethod.pickup,
    );

    final deliveryRaw = map['delivery'];
    final timingRaw = map['timing'];
    final paymentRaw = map['payment'];
    final linesRaw = map['lines'];

    return PlacedOrder(
      id: id,
      displayCode: map['displayCode'] as String? ?? id,
      userId: map['userId'] as String?,
      lines: _parseLines(linesRaw),
      method: method,
      pickupLocation: map['pickupLocation'] as String?,
      delivery: deliveryRaw is Map
          ? DeliveryDetails.fromMap(Map<String, dynamic>.from(deliveryRaw))
          : null,
      timing: timingRaw is Map
          ? OrderTiming.fromMap(Map<String, dynamic>.from(timingRaw))
          : const OrderTiming(),
      expectedPrepMinutes: (map['expectedPrepMinutes'] as num?)?.toInt() ?? 20,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0,
      total: (map['total'] as num?)?.toDouble() ?? 0,
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      status: parseOrderStatus(map['status'] as String?),
      payment: paymentRaw is Map
          ? OrderPayment.fromMap(Map<String, dynamic>.from(paymentRaw))
          : null,
    );
  }

  static List<CartLineItem> _parseLines(Object? raw) {
    if (raw is! List) return const [];
    final lines = <CartLineItem>[];
    for (final entry in raw) {
      if (entry is Map<String, dynamic>) {
        lines.add(CartLineItem.fromOrderMap(entry));
      } else if (entry is Map) {
        lines.add(CartLineItem.fromOrderMap(Map<String, dynamic>.from(entry)));
      }
    }
    return List.unmodifiable(lines);
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    // Firestore Timestamp without importing cloud_firestore in domain.
    try {
      final dynamic dynamicValue = value;
      final date = dynamicValue.toDate();
      if (date is DateTime) return date;
    } catch (_) {}
    return null;
  }
}

/// Kitchen / fulfillment progress for track-order timelines.
///
/// Pickup: received → confirmed → preparing → ready → completed
/// Delivery: received → confirmed → preparing → outForDelivery → delivered
enum OrderStatus {
  /// Order just placed / payment captured.
  received,

  /// Kitchen acknowledged the order.
  confirmed,

  preparing,
  ready,

  /// Delivery only — courier has left.
  outForDelivery,

  /// Pickup terminal status.
  completed,

  /// Delivery terminal status.
  delivered,

  cancelled,
}

/// Maps Firestore / persisted status names, including legacy `recorded`.
OrderStatus parseOrderStatus(String? name) {
  if (name == null || name.isEmpty) return OrderStatus.received;
  if (name == 'recorded') return OrderStatus.confirmed;
  return OrderStatus.values.firstWhere(
    (value) => value.name == name,
    orElse: () => OrderStatus.received,
  );
}

extension OrderStatusLabels on OrderStatus {
  String get label => switch (this) {
        OrderStatus.received => 'Order Received',
        OrderStatus.confirmed => 'Confirmed',
        OrderStatus.preparing => 'Preparing',
        OrderStatus.ready => 'Ready',
        OrderStatus.outForDelivery => 'Out for Delivery',
        OrderStatus.completed => 'Completed',
        OrderStatus.delivered => 'Delivered',
        OrderStatus.cancelled => 'Cancelled',
      };
}
