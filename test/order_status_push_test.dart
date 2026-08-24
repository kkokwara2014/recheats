import 'package:flutter_test/flutter_test.dart';
import 'package:recheats/features/notifications/domain/order_status_push.dart';
import 'package:recheats/features/orders/domain/placed_order.dart';

void main() {
  group('OrderStatusPush', () {
    test('maps kitchen statuses to customer copy', () {
      expect(
        OrderStatusPush.bodyFor(OrderStatus.confirmed),
        'Your order has been confirmed.',
      );
      expect(
        OrderStatusPush.bodyFor(OrderStatus.preparing),
        'Your order is being prepared.',
      );
      expect(
        OrderStatusPush.bodyFor(OrderStatus.ready),
        'Your order is ready for pickup.',
      );
      expect(
        OrderStatusPush.bodyFor(OrderStatus.outForDelivery),
        'Your order is on its way.',
      );
      expect(
        OrderStatusPush.bodyFor(OrderStatus.delivered),
        'Your order has been delivered. Enjoy your meal! ❤️',
      );
      expect(
        OrderStatusPush.bodyFor(OrderStatus.completed),
        OrderStatusPush.bodyFor(OrderStatus.delivered),
      );
    });

    test('skips received and cancelled', () {
      expect(OrderStatusPush.bodyFor(OrderStatus.received), isNull);
      expect(OrderStatusPush.bodyFor(OrderStatus.cancelled), isNull);
    });

    test('uses RechEats title', () {
      expect(OrderStatusPush.title, 'RechEats');
    });
  });
}
