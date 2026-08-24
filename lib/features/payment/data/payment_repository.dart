import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../../../core/config/app_env.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/collect_payment_request.dart';
import '../domain/order_payment.dart';
import '../domain/payment_method_kind.dart';
import '../domain/payment_result.dart';
import '../domain/payment_session.dart';
import '../domain/payment_status.dart';
import 'payment_intent_backend.dart';
import 'stripe_bootstrap.dart';

/// Collects payment via Stripe PaymentSheet; never stores card data in Firebase.
abstract class PaymentRepository {
  /// Methods to advertise in checkout UI for the current platform / config.
  List<PaymentMethodKind> get supportedMethods;

  /// Whether a real Stripe publishable key + mobile platform are available.
  bool get isLiveStripeConfigured;

  Future<PaymentResult> collectPayment(CollectPaymentRequest request);
}

/// Dev / desktop / tests: succeeds without opening Stripe UI.
class MockPaymentRepository implements PaymentRepository {
  MockPaymentRepository({
    PaymentIntentBackend? backend,
    this.succeed = true,
    this.failMessage = 'Mock payment failed.',
  }) : _backend = backend ?? MockPaymentIntentBackend();

  final PaymentIntentBackend _backend;
  final bool succeed;
  final String failMessage;

  bool canceledNext = false;
  bool failNext = false;

  @override
  bool get isLiveStripeConfigured => false;

  @override
  List<PaymentMethodKind> get supportedMethods => const [
        PaymentMethodKind.card,
        PaymentMethodKind.applePay,
        PaymentMethodKind.googlePay,
      ];

  @override
  Future<PaymentResult> collectPayment(CollectPaymentRequest request) async {
    if (canceledNext) {
      canceledNext = false;
      return const PaymentCanceled();
    }
    if (failNext || !succeed) {
      failNext = false;
      return PaymentFailed(failMessage);
    }

    final sessionResult = await _backend.createPaymentIntent(request);
    return sessionResult.when(
      success: (session) => PaymentSucceeded(
        mockSucceededPayment(
          amountCents: request.amountCents,
          paymentIntentId: session.paymentIntentId,
        ),
      ),
      failure: (error, _) => PaymentFailed(
        error is AppException ? error.message : failMessage,
        cause: error,
      ),
    );
  }
}

/// Stripe PaymentSheet: cards + Apple Pay / Google Pay where the OS supports them.
class StripePaymentRepository implements PaymentRepository {
  StripePaymentRepository({
    required PaymentIntentBackend backend,
  }) : _backend = backend;

  final PaymentIntentBackend _backend;

  @override
  bool get isLiveStripeConfigured => StripeBootstrap.isReady;

  @override
  List<PaymentMethodKind> get supportedMethods {
    final methods = <PaymentMethodKind>[PaymentMethodKind.card];
    if (StripeBootstrap.supportsApplePay) {
      methods.add(PaymentMethodKind.applePay);
    }
    if (StripeBootstrap.supportsGooglePay) {
      methods.add(PaymentMethodKind.googlePay);
    }
    return methods;
  }

  @override
  Future<PaymentResult> collectPayment(CollectPaymentRequest request) async {
    if (!StripeBootstrap.isReady) {
      return const PaymentFailed(
        'Stripe is not configured. Add STRIPE_PUBLISHABLE_KEY to run live '
        'payments.',
      );
    }

    final sessionResult = await _backend.createPaymentIntent(request);
    final session = sessionResult.valueOrNull;
    if (session == null) {
      final error = sessionResult.errorOrNull;
      return PaymentFailed(
        error is AppException
            ? error.message
            : 'Could not start payment. Try again.',
        cause: error,
      );
    }

    // Mock backend secrets are not valid with Stripe — treat as local success
    // so checkout works before the Cloud Function is deployed.
    if (session.clientSecret.endsWith('_secret_mock') ||
        session.paymentIntentId.startsWith('pi_mock')) {
      return PaymentSucceeded(
        mockSucceededPayment(
          amountCents: request.amountCents,
          paymentIntentId: session.paymentIntentId,
        ),
      );
    }

    try {
      await _initPaymentSheet(session, request);
      await Stripe.instance.presentPaymentSheet();

      return PaymentSucceeded(
        OrderPayment(
          provider: 'stripe',
          paymentIntentId: session.paymentIntentId,
          status: PaymentStatus.succeeded,
          methodKind: PaymentMethodKind.card,
          amountCents: request.amountCents,
          currency: request.currency,
        ),
      );
    } on StripeException catch (error, stackTrace) {
      if (error.error.code == FailureCode.Canceled) {
        return const PaymentCanceled();
      }
      if (kDebugMode) {
        debugPrint('Stripe PaymentSheet failed: $error\n$stackTrace');
      }
      return PaymentFailed(
        error.error.localizedMessage ??
            'Payment could not be completed. Try another method.',
        cause: error,
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('PaymentSheet unexpected error: $error\n$stackTrace');
      }
      return PaymentFailed(
        'Payment could not be completed. Please try again.',
        cause: error,
      );
    }
  }

  Future<void> _initPaymentSheet(
    PaymentSession session,
    CollectPaymentRequest request,
  ) async {
    final applePay = StripeBootstrap.supportsApplePay
        ? PaymentSheetApplePay(
            merchantCountryCode: AppEnv.stripeMerchantCountryCode,
          )
        : null;

    final googlePay = StripeBootstrap.supportsGooglePay
        ? PaymentSheetGooglePay(
            merchantCountryCode: AppEnv.stripeMerchantCountryCode,
            testEnv: !AppEnv.environment.isProd,
            currencyCode: request.currency.toUpperCase(),
          )
        : null;

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: session.clientSecret,
        merchantDisplayName: AppStrings.appName,
        customerId: session.customerId,
        customerEphemeralKeySecret: session.ephemeralKeySecret,
        style: ThemeMode.system,
        billingDetails: BillingDetails(
          email: request.customerEmail,
          name: request.customerName,
        ),
        applePay: applePay,
        googlePay: googlePay,
      ),
    );
  }
}

/// Test double with controllable outcomes (same idea as [FakeOrderRepository]).
class FakePaymentRepository implements PaymentRepository {
  FakePaymentRepository();

  final List<CollectPaymentRequest> requests = [];
  bool canceledNext = false;
  bool failNext = false;
  String failMessage = 'Could not complete payment.';
  PaymentMethodKind methodKind = PaymentMethodKind.card;

  @override
  bool get isLiveStripeConfigured => false;

  @override
  List<PaymentMethodKind> get supportedMethods => const [
        PaymentMethodKind.card,
        PaymentMethodKind.applePay,
        PaymentMethodKind.googlePay,
      ];

  @override
  Future<PaymentResult> collectPayment(CollectPaymentRequest request) async {
    requests.add(request);
    if (canceledNext) {
      canceledNext = false;
      return const PaymentCanceled();
    }
    if (failNext) {
      failNext = false;
      return PaymentFailed(failMessage);
    }
    return PaymentSucceeded(
      mockSucceededPayment(
        amountCents: request.amountCents,
        methodKind: methodKind,
      ),
    );
  }
}
