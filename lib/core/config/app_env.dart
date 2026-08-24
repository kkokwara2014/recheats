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
/// ```
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

  static AppEnvironment get environment => AppEnvironment.fromName(_envName);

  static String get label => environment.name;
}
