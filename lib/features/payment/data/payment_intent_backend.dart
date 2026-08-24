import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_env.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/result.dart';
import '../domain/collect_payment_request.dart';
import '../domain/payment_session.dart';

/// Creates Stripe PaymentIntents on a trusted backend (never in the app).
abstract class PaymentIntentBackend {
  Future<Result<PaymentSession>> createPaymentIntent(
    CollectPaymentRequest request,
  );
}

/// Local / CI path when no [AppEnv.paymentBackendUrl] is set.
///
/// Returns a fake client secret so UI flows can be exercised without Stripe.
/// [StripePaymentRepository] skips the real PaymentSheet in that case.
class MockPaymentIntentBackend implements PaymentIntentBackend {
  MockPaymentIntentBackend({this.idPrefix = 'pi_mock'});

  final String idPrefix;
  int _n = 0;

  @override
  Future<Result<PaymentSession>> createPaymentIntent(
    CollectPaymentRequest request,
  ) async {
    if (request.amountCents <= 0) {
      return const Failure(
        ValidationException('Order total must be greater than zero.'),
      );
    }
    _n += 1;
    final id = '${idPrefix}_$_n';
    return Success(
      PaymentSession(
        paymentIntentId: id,
        clientSecret: '${id}_secret_mock',
      ),
    );
  }
}

/// POSTs to [AppEnv.paymentBackendUrl] (Cloud Function or other HTTPS API).
///
/// Expected JSON response:
/// ```json
/// {
///   "paymentIntentId": "pi_…",
///   "clientSecret": "pi_…_secret_…",
///   "customerId": "cus_…",          // optional
///   "ephemeralKeySecret": "ek_…"    // optional
/// }
/// ```
class HttpPaymentIntentBackend implements PaymentIntentBackend {
  HttpPaymentIntentBackend({
    http.Client? client,
    String? url,
  })  : _client = client ?? http.Client(),
        _url = url ?? AppEnv.paymentBackendUrl;

  final http.Client _client;
  final String _url;

  @override
  Future<Result<PaymentSession>> createPaymentIntent(
    CollectPaymentRequest request,
  ) async {
    if (_url.isEmpty) {
      return const Failure(
        PaymentException(
          'Payment backend is not configured. Set PAYMENT_BACKEND_URL.',
        ),
      );
    }
    if (request.amountCents <= 0) {
      return const Failure(
        ValidationException('Order total must be greater than zero.'),
      );
    }

    try {
      final response = await _client.post(
        Uri.parse(_url),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toBackendBody()),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (kDebugMode) {
          debugPrint(
            'PaymentIntent backend ${response.statusCode}: ${response.body}',
          );
        }
        return Failure(
          PaymentException(
            'Could not start payment (${response.statusCode}). Try again.',
          ),
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return const Failure(
          PaymentException('Payment backend returned an unexpected response.'),
        );
      }

      return Success(PaymentSession.fromJson(decoded));
    } on FormatException catch (error, stackTrace) {
      return Failure(
        PaymentException(
          'Payment backend returned invalid data.',
          cause: error,
          stackTrace: stackTrace,
        ),
        stackTrace,
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('PaymentIntent backend failed: $error\n$stackTrace');
      }
      return Failure(
        PaymentException(
          'Could not reach the payment service. Check your connection.',
          cause: error,
          stackTrace: stackTrace,
        ),
        stackTrace,
      );
    }
  }
}
