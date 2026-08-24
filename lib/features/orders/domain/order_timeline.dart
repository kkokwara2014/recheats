import '../../shop/domain/fulfillment_method.dart';
import 'placed_order.dart';

/// Pickup / delivery status steps for the track-order timeline (no GPS).
abstract final class OrderTimeline {
  static const List<OrderStatus> pickupSteps = [
    OrderStatus.received,
    OrderStatus.confirmed,
    OrderStatus.preparing,
    OrderStatus.ready,
    OrderStatus.completed,
  ];

  static const List<OrderStatus> deliverySteps = [
    OrderStatus.received,
    OrderStatus.confirmed,
    OrderStatus.preparing,
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
  ];

  static List<OrderStatus> stepsFor(FulfillmentMethod method) =>
      method == FulfillmentMethod.delivery ? deliverySteps : pickupSteps;

  /// Index of [status] on the fulfillment timeline, or `-1` if cancelled /
  /// unknown.
  static int stepIndex(OrderStatus status, FulfillmentMethod method) =>
      stepsFor(method).indexOf(status);

  /// Active step index for UI highlighting (never negative).
  static int activeIndex(OrderStatus status, FulfillmentMethod method) {
    final index = stepIndex(status, method);
    return index < 0 ? 0 : index;
  }

  static bool isTerminal(OrderStatus status) =>
      status == OrderStatus.completed ||
      status == OrderStatus.delivered ||
      status == OrderStatus.cancelled;
}
