import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_env.dart';
import '../data/payment_intent_backend.dart';
import '../data/payment_repository.dart';
import '../data/stripe_bootstrap.dart';
import '../domain/payment_method_kind.dart';

final paymentIntentBackendProvider = Provider<PaymentIntentBackend>((ref) {
  if (AppEnv.hasPaymentBackend) {
    return HttpPaymentIntentBackend();
  }
  return MockPaymentIntentBackend();
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final backend = ref.watch(paymentIntentBackendProvider);
  if (StripeBootstrap.isReady) {
    return StripePaymentRepository(backend: backend);
  }
  return MockPaymentRepository(backend: backend);
});

final supportedPaymentMethodsProvider = Provider<List<PaymentMethodKind>>((ref) {
  return ref.watch(paymentRepositoryProvider).supportedMethods;
});
