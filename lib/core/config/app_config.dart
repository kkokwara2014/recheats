import 'package:package_info_plus/package_info_plus.dart';

import 'app_env.dart';

/// Resolved app metadata available after [AppConfig.ensureInitialized].
class AppConfig {
  AppConfig._({
    required this.environment,
    required this.appName,
    required this.packageName,
    required this.version,
    required this.buildNumber,
  });

  final AppEnvironment environment;
  final String appName;
  final String packageName;
  final String version;
  final String buildNumber;

  static AppConfig? _instance;

  static AppConfig get instance {
    final value = _instance;
    if (value == null) {
      throw StateError(
        'AppConfig.ensureInitialized() must be called before use.',
      );
    }
    return value;
  }

  static bool get isInitialized => _instance != null;

  static Future<AppConfig> ensureInitialized() async {
    if (_instance != null) return _instance!;

    final info = await PackageInfo.fromPlatform();
    _instance = AppConfig._(
      environment: AppEnv.environment,
      appName: info.appName,
      packageName: info.packageName,
      version: info.version,
      buildNumber: info.buildNumber,
    );
    return _instance!;
  }

  String get versionLabel => '$version+$buildNumber';
}
