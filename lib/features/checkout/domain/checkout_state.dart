import '../../../core/constants/app_strings.dart';
import '../../cart/domain/cart_state.dart';
import '../../shop/domain/fulfillment_method.dart';
import '../../shop/domain/shop_fulfillment_settings.dart';
import 'delivery_details.dart';
import 'order_timing.dart';

/// Customer checkout draft: fulfillment, timing, and delivery fields.
class CheckoutState {
  const CheckoutState({
    this.method,
    this.delivery = const DeliveryDetails(),
    this.timing = const OrderTiming(),
  });

  final FulfillmentMethod? method;
  final DeliveryDetails delivery;
  final OrderTiming timing;

  bool get isPickup => method == FulfillmentMethod.pickup;

  bool get isDelivery => method == FulfillmentMethod.delivery;

  double deliveryFee(ShopFulfillmentSettings settings) {
    final selected = method;
    if (selected == null) return 0;
    return settings.feeFor(selected);
  }

  double total(CartState cart, ShopFulfillmentSettings settings) {
    return cart.subtotal + deliveryFee(settings);
  }

  String formattedDeliveryFee(ShopFulfillmentSettings settings) =>
      '\$${deliveryFee(settings).toStringAsFixed(2)}';

  String formattedTotal(CartState cart, ShopFulfillmentSettings settings) =>
      '\$${total(cart, settings).toStringAsFixed(2)}';

  String? validationMessage(ShopFulfillmentSettings settings) {
    final selected = method;
    if (selected == null) {
      return AppStrings.checkoutSelectMethod;
    }
    if (!settings.supports(selected)) {
      return AppStrings.checkoutMethodUnavailable;
    }
    if (selected == FulfillmentMethod.delivery && !delivery.isComplete) {
      return AppStrings.checkoutDeliveryAddressRequired;
    }
    if (!timing.isComplete) {
      if (timing.isScheduled && timing.scheduledAt == null) {
        return AppStrings.checkoutScheduleRequired;
      }
      return AppStrings.checkoutScheduleInPast;
    }
    return null;
  }

  CheckoutState copyWith({
    FulfillmentMethod? method,
    bool clearMethod = false,
    DeliveryDetails? delivery,
    OrderTiming? timing,
  }) {
    return CheckoutState(
      method: clearMethod ? null : (method ?? this.method),
      delivery: delivery ?? this.delivery,
      timing: timing ?? this.timing,
    );
  }
}
