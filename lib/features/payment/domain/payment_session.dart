/// Client-safe PaymentIntent fields returned by the backend.
///
/// Never includes the Stripe secret key or raw card numbers.
class PaymentSession {
  const PaymentSession({
    required this.paymentIntentId,
    required this.clientSecret,
    this.customerId,
    this.ephemeralKeySecret,
  });

  final String paymentIntentId;
  final String clientSecret;
  final String? customerId;
  final String? ephemeralKeySecret;

  factory PaymentSession.fromJson(Map<String, dynamic> json) {
    final clientSecret = json['clientSecret'] as String? ??
        json['paymentIntentClientSecret'] as String?;
    final paymentIntentId = json['paymentIntentId'] as String? ??
        json['id'] as String? ??
        _idFromClientSecret(clientSecret);

    if (clientSecret == null || clientSecret.isEmpty) {
      throw const FormatException('Payment session missing clientSecret.');
    }
    if (paymentIntentId == null || paymentIntentId.isEmpty) {
      throw const FormatException('Payment session missing paymentIntentId.');
    }

    return PaymentSession(
      paymentIntentId: paymentIntentId,
      clientSecret: clientSecret,
      customerId: json['customerId'] as String? ?? json['customer'] as String?,
      ephemeralKeySecret: json['ephemeralKeySecret'] as String? ??
          json['ephemeralKey'] as String?,
    );
  }

  static String? _idFromClientSecret(String? clientSecret) {
    if (clientSecret == null || !clientSecret.contains('_secret_')) {
      return null;
    }
    return clientSecret.split('_secret_').first;
  }
}
