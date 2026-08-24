/// Customer-facing ways to pay. Card data never enters Firebase — Stripe
/// PaymentSheet collects and tokenizes it.
enum PaymentMethodKind {
  card,
  applePay,
  googlePay,
}

extension PaymentMethodKindX on PaymentMethodKind {
  String get displayLabel => switch (this) {
        PaymentMethodKind.card => 'Card',
        PaymentMethodKind.applePay => 'Apple Pay',
        PaymentMethodKind.googlePay => 'Google Pay',
      };
}
