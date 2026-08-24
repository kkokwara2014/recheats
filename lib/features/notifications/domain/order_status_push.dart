import '../../orders/domain/placed_order.dart';

/// Customer-facing FCM copy for kitchen status advances (Module 16).
abstract final class OrderStatusPush {
  static const String title = 'RechEats';

  /// Body text for a status change, or null when no push should be sent.
  static String? bodyFor(OrderStatus status) {
    return switch (status) {
      OrderStatus.confirmed => 'Your order has been confirmed.',
      OrderStatus.preparing => 'Your order is being prepared.',
      OrderStatus.ready => 'Your order is ready for pickup.',
      OrderStatus.outForDelivery => 'Your order is on its way.',
      OrderStatus.delivered || OrderStatus.completed =>
        'Your order has been delivered. Enjoy your meal! ❤️',
      OrderStatus.received || OrderStatus.cancelled => null,
    };
  }
}
