import '../../cart/domain/cart_line_item.dart';
import '../../checkout/domain/delivery_details.dart';
import '../../checkout/domain/order_timing.dart';
import '../../payment/domain/order_payment.dart';
import '../../shop/domain/fulfillment_method.dart';

/// Payload to persist a checkout as an order after Stripe payment succeeds.
class PlaceOrderRequest {
  const PlaceOrderRequest({
    required this.lines,
    required this.method,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    this.userId,
    this.pickupLocation,
    this.delivery,
    this.timing = const OrderTiming(),
    this.expectedPrepMinutes = 20,
    this.payment,
  });

  final String? userId;
  final List<CartLineItem> lines;
  final FulfillmentMethod method;
  final String? pickupLocation;
  final DeliveryDetails? delivery;
  final OrderTiming timing;
  final int expectedPrepMinutes;
  final double subtotal;
  final double deliveryFee;
  final double total;

  /// Stripe identifiers + status only — never card PANs.
  final OrderPayment? payment;
}
