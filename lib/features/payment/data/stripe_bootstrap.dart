import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../../../core/config/app_env.dart';

/// Configures the Stripe SDK with the publishable key only (never the secret).
abstract final class StripeBootstrap {
  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static bool get isReady =>
      _initialized && AppEnv.hasStripePublishableKey && _isMobilePlatform;

  static bool get _isMobilePlatform {
    if (kIsWeb) return true;
    try {
      return Platform.isIOS || Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }

  static bool get supportsApplePay {
    if (kIsWeb) return false;
    try {
      return Platform.isIOS && AppEnv.stripeMerchantIdentifier.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static bool get supportsGooglePay {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }

  /// Call once from [main] after [WidgetsFlutterBinding.ensureInitialized].
  static Future<void> initialize() async {
    if (!AppEnv.hasStripePublishableKey) {
      if (kDebugMode) {
        debugPrint(
          'Stripe: STRIPE_PUBLISHABLE_KEY not set — using mock payments.',
        );
      }
      return;
    }

    if (!_isMobilePlatform && !kIsWeb) {
      if (kDebugMode) {
        debugPrint(
          'Stripe: PaymentSheet is not supported on this platform — mock '
          'payments will be used.',
        );
      }
      return;
    }

    Stripe.publishableKey = AppEnv.stripePublishableKey;
    if (AppEnv.stripeMerchantIdentifier.isNotEmpty) {
      Stripe.merchantIdentifier = AppEnv.stripeMerchantIdentifier;
    }
    await Stripe.instance.applySettings();
    _initialized = true;

    if (kDebugMode) {
      debugPrint('Stripe SDK ready (merchant country US).');
    }
  }
}
