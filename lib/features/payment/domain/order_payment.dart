import 'payment_method_kind.dart';
import 'payment_status.dart';

/// Payment snapshot attached to a placed order.
///
/// Stores Stripe identifiers and status only — never card PANs, CVVs, or
/// wallet tokens. Those stay with Stripe.
class OrderPayment {
  const OrderPayment({
    required this.provider,
    required this.paymentIntentId,
    required this.status,
    this.methodKind,
    this.amountCents,
    this.currency = 'usd',
  });

  /// Always `stripe` for Module 13 (US).
  final String provider;

  final String paymentIntentId;
  final PaymentStatus status;
  final PaymentMethodKind? methodKind;
  final int? amountCents;
  final String currency;

  bool get isPaid => status == PaymentStatus.succeeded;

  Map<String, dynamic> toMap() => {
        'provider': provider,
        'paymentIntentId': paymentIntentId,
        'status': status.name,
        if (methodKind != null) 'methodKind': methodKind!.name,
        if (amountCents != null) 'amountCents': amountCents,
        'currency': currency,
      };

  factory OrderPayment.fromMap(Map<String, dynamic> map) {
    return OrderPayment(
      provider: map['provider'] as String? ?? 'stripe',
      paymentIntentId: map['paymentIntentId'] as String? ?? '',
      status: PaymentStatus.values.firstWhere(
        (value) => value.name == map['status'],
        orElse: () => PaymentStatus.failed,
      ),
      methodKind: PaymentMethodKind.values
          .where((value) => value.name == map['methodKind'])
          .firstOrNull,
      amountCents: (map['amountCents'] as num?)?.toInt(),
      currency: map['currency'] as String? ?? 'usd',
    );
  }
}
