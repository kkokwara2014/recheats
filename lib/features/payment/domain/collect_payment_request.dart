/// Amount and metadata for creating a Stripe PaymentIntent (USD cents).
class CollectPaymentRequest {
  const CollectPaymentRequest({
    required this.amountCents,
    required this.currency,
    this.orderId,
    this.customerEmail,
    this.customerName,
    this.description,
  });

  /// Charge amount in the smallest currency unit (cents for USD).
  final int amountCents;

  /// Lowercase ISO currency — RechEats uses `usd`.
  final String currency;

  final String? orderId;
  final String? customerEmail;
  final String? customerName;
  final String? description;

  Map<String, dynamic> toBackendBody() => {
        'amount': amountCents,
        'currency': currency,
        if (orderId != null) 'orderId': orderId,
        if (customerEmail != null) 'customerEmail': customerEmail,
        if (customerName != null) 'customerName': customerName,
        if (description != null) 'description': description,
      };
}
