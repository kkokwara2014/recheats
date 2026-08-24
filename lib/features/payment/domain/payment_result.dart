import 'order_payment.dart';
import 'payment_method_kind.dart';
import 'payment_status.dart';

/// Outcome of presenting Stripe PaymentSheet (or a local mock).
sealed class PaymentResult {
  const PaymentResult();
}

final class PaymentSucceeded extends PaymentResult {
  const PaymentSucceeded(this.payment);

  final OrderPayment payment;
}

final class PaymentCanceled extends PaymentResult {
  const PaymentCanceled();
}

final class PaymentFailed extends PaymentResult {
  const PaymentFailed(this.message, {this.cause});

  final String message;
  final Object? cause;
}

/// Convenience when a mock or test needs a succeeded [OrderPayment].
OrderPayment mockSucceededPayment({
  required int amountCents,
  String paymentIntentId = 'pi_mock_local',
  PaymentMethodKind methodKind = PaymentMethodKind.card,
}) {
  return OrderPayment(
    provider: 'stripe',
    paymentIntentId: paymentIntentId,
    status: PaymentStatus.succeeded,
    methodKind: methodKind,
    amountCents: amountCents,
    currency: 'usd',
  );
}
