/// Runtime environment selected via `--dart-define=ENV=dev|staging|prod`.
enum AppEnvironment {
  dev,
  staging,
  prod;

  static AppEnvironment fromName(String? raw) {
    switch ((raw ?? 'dev').toLowerCase()) {
      case 'staging':
      case 'stage':
        return AppEnvironment.staging;
      case 'prod':
      case 'production':
        return AppEnvironment.prod;
      case 'dev':
      case 'development':
      default:
        return AppEnvironment.dev;
    }
  }

  bool get isProd => this == AppEnvironment.prod;
  bool get isDev => this == AppEnvironment.dev;
}

/// Compile-time configuration. Pass values with `--dart-define`.
///
/// Examples:
/// ```
/// flutter run --dart-define=ENV=dev --dart-define=USE_FIREBASE=false
/// flutter run --dart-define=ENV=prod --dart-define=USE_FIREBASE=true
/// flutter run \
///   --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_... \
///   --dart-define=STRIPE_MERCHANT_IDENTIFIER=merchant.org.recheats \
///   --dart-define=PAYMENT_BACKEND_URL=https://.../createPaymentIntent
/// ```
///
/// Never pass the Stripe **secret** key into the app. PaymentIntents are
/// created only on the backend (`functions/` or [paymentBackendUrl]).
abstract final class AppEnv {
  static const String _envName = String.fromEnvironment(
    'ENV',
    defaultValue: 'dev',
  );

  static const bool useFirebase = bool.fromEnvironment(
    'USE_FIREBASE',
    defaultValue: false,
  );

  static const bool enableAnalytics = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: true,
  );

  static const bool enableCrashlytics = bool.fromEnvironment(
    'ENABLE_CRASHLYTICS',
    defaultValue: true,
  );

  static const bool enableAppCheck = bool.fromEnvironment(
    'ENABLE_APP_CHECK',
    defaultValue: false,
  );

  /// Stripe publishable key only (`pk_test_…` / `pk_live_…`).
  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  /// Apple Pay merchant ID (PassKit). Empty disables Apple Pay config.
  static const String stripeMerchantIdentifier = String.fromEnvironment(
    'STRIPE_MERCHANT_IDENTIFIER',
    defaultValue: 'merchant.org.recheats',
  );

  /// HTTPS endpoint that creates a Stripe PaymentIntent and returns
  /// `{ clientSecret, paymentIntentId }` (and optional customer fields).
  static const String paymentBackendUrl = String.fromEnvironment(
    'PAYMENT_BACKEND_URL',
    defaultValue: '',
  );

  /// ISO country for Stripe PaymentSheet wallets (US — Rockville, MD).
  static const String stripeMerchantCountryCode = String.fromEnvironment(
    'STRIPE_MERCHANT_COUNTRY_CODE',
    defaultValue: 'US',
  );

  static AppEnvironment get environment => AppEnvironment.fromName(_envName);

  static String get label => environment.name;

  static bool get hasStripePublishableKey => stripePublishableKey.isNotEmpty;

  static bool get hasPaymentBackend => paymentBackendUrl.isNotEmpty;
}
