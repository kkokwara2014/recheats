import '../../../core/constants/app_strings.dart';
import '../../cart/domain/cart_state.dart';
import 'fulfillment_method.dart';

/// Rechael's kitchen fulfillment options — no rider fleet in MVP.
class ShopFulfillmentSettings {
  const ShopFulfillmentSettings({
    this.pickupEnabled = true,
    this.deliveryEnabled = true,
    this.pickupLocation = AppStrings.locationHint,
    this.deliveryFee = kCartDeliveryFee,
  });

  final bool pickupEnabled;
  final bool deliveryEnabled;

  /// Shown to customers who choose pickup.
  final String pickupLocation;

  /// Flat fee charged when the customer chooses delivery.
  final double deliveryFee;

  static const ShopFulfillmentSettings defaults = ShopFulfillmentSettings();

  bool get offersPickup => pickupEnabled;

  bool get offersDelivery => deliveryEnabled;

  bool get hasAnyMethod => offersPickup || offersDelivery;

  /// Preferred default when opening checkout.
  FulfillmentMethod? get preferredMethod {
    if (offersPickup) return FulfillmentMethod.pickup;
    if (offersDelivery) return FulfillmentMethod.delivery;
    return null;
  }

  bool supports(FulfillmentMethod method) {
    return switch (method) {
      FulfillmentMethod.pickup => offersPickup,
      FulfillmentMethod.delivery => offersDelivery,
    };
  }

  double feeFor(FulfillmentMethod method) {
    return switch (method) {
      FulfillmentMethod.pickup => 0,
      FulfillmentMethod.delivery => deliveryFee < 0 ? 0 : deliveryFee,
    };
  }

  ShopFulfillmentSettings copyWith({
    bool? pickupEnabled,
    bool? deliveryEnabled,
    String? pickupLocation,
    double? deliveryFee,
  }) {
    return ShopFulfillmentSettings(
      pickupEnabled: pickupEnabled ?? this.pickupEnabled,
      deliveryEnabled: deliveryEnabled ?? this.deliveryEnabled,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      deliveryFee: deliveryFee ?? this.deliveryFee,
    );
  }

  Map<String, dynamic> toMap() => {
        'pickupEnabled': pickupEnabled,
        'deliveryEnabled': deliveryEnabled,
        'pickupLocation': pickupLocation,
        'deliveryFee': deliveryFee,
      };

  factory ShopFulfillmentSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return defaults;

    final feeRaw = map['deliveryFee'];
    final fee = feeRaw is num
        ? feeRaw.toDouble()
        : double.tryParse('$feeRaw') ?? kCartDeliveryFee;

    return ShopFulfillmentSettings(
      pickupEnabled: map['pickupEnabled'] as bool? ?? true,
      deliveryEnabled: map['deliveryEnabled'] as bool? ?? true,
      pickupLocation: (map['pickupLocation'] as String?)?.trim().isNotEmpty ==
              true
          ? (map['pickupLocation'] as String).trim()
          : AppStrings.locationHint,
      deliveryFee: fee,
    );
  }
}
