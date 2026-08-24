import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/app_env.dart';
import '../../firebase_options.dart';
import 'firebase_services.dart';

/// Initializes Firebase and related foundation services.
class FirebaseBootstrap {
  FirebaseBootstrap._();

  static FirebaseBootstrapResult? _result;
  static AnalyticsService analytics = const AnalyticsService(enabled: false);
  static CrashlyticsService crashlytics = CrashlyticsService(enabled: false);
  static MessagingService messaging = const MessagingService(enabled: false);
  static AppCheckService appCheck = const AppCheckService(enabled: false);

  static FirebaseBootstrapResult get result =>
      _result ??
      const FirebaseBootstrapResult(status: FirebaseBootstrapStatus.disabled);

  static Future<FirebaseBootstrapResult> initialize() async {
    if (!AppEnv.useFirebase) {
      _result = const FirebaseBootstrapResult(
        status: FirebaseBootstrapStatus.disabled,
      );
      _installNoopServices();
      return _result!;
    }

    if (!DefaultFirebaseOptions.isConfigured) {
      _result = const FirebaseBootstrapResult(
        status: FirebaseBootstrapStatus.notConfigured,
      );
      _installNoopServices();
      return _result!;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      await _configureAppCheck();
      await _configureCrashlytics();
      await _configureAnalytics();
      await _configureMessaging();

      _result = const FirebaseBootstrapResult(
        status: FirebaseBootstrapStatus.ready,
      );
      return _result!;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Firebase bootstrap failed: $error\n$stackTrace');
      }
      _installNoopServices();
      _result = FirebaseBootstrapResult(
        status: FirebaseBootstrapStatus.failed,
        error: error,
      );
      return _result!;
    }
  }

  static void _installNoopServices() {
    analytics = AnalyticsService(enabled: false);
    crashlytics = CrashlyticsService(enabled: false);
    messaging = const MessagingService(enabled: false);
    appCheck = const AppCheckService(enabled: false);
  }

  static Future<void> _configureAppCheck() async {
    final enabled = AppEnv.enableAppCheck && !kIsWeb;
    appCheck = AppCheckService(enabled: enabled);
    if (!enabled) return;

    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleDeviceCheckProvider(),
    );
  }

  static Future<void> _configureCrashlytics() async {
    final supported = !kIsWeb;
    final enabled = AppEnv.enableCrashlytics && supported;
    crashlytics = _LiveCrashlyticsService(enabled: enabled);

    if (!enabled) return;

    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      !kDebugMode,
    );
  }

  static Future<void> _configureAnalytics() async {
    final enabled = AppEnv.enableAnalytics;
    analytics = _LiveAnalyticsService(enabled: enabled);
    if (!enabled) return;
    await FirebaseAnalytics.instance.logAppOpen();
  }

  static Future<void> _configureMessaging() async {
    messaging = _LiveMessagingService(enabled: true);
  }
}

class _LiveAnalyticsService extends AnalyticsService {
  const _LiveAnalyticsService({required super.enabled});

  FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;

  @override
  Future<void> logAppOpen() async {
    if (!enabled) return;
    await _analytics.logAppOpen();
  }

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    if (!enabled) return;
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  @override
  Future<void> setUserId(String? userId) async {
    if (!enabled) return;
    await _analytics.setUserId(id: userId);
  }
}

class _LiveCrashlyticsService extends CrashlyticsService {
  _LiveCrashlyticsService({required super.enabled});

  FirebaseCrashlytics get _crashlytics => FirebaseCrashlytics.instance;

  @override
  Future<void> recordFlutterFatalError(FlutterErrorDetails details) async {
    if (!enabled) {
      await super.recordFlutterFatalError(details);
      return;
    }
    await _crashlytics.recordFlutterFatalError(details);
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  }) async {
    if (!enabled) {
      await super.recordError(error, stack, fatal: fatal);
      return;
    }
    await _crashlytics.recordError(error, stack, fatal: fatal);
  }

  @override
  Future<void> setUserIdentifier(String userId) async {
    if (!enabled) return;
    await _crashlytics.setUserIdentifier(userId);
  }

  @override
  Future<void> log(String message) async {
    if (!enabled) return;
    await _crashlytics.log(message);
  }
}

class _LiveMessagingService extends MessagingService {
  const _LiveMessagingService({required super.enabled});

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  @override
  Future<String?> getToken() async {
    if (!enabled) return null;
    return _messaging.getToken();
  }

  @override
  Future<void> requestPermission() async {
    if (!enabled) return;
    await _messaging.requestPermission();
  }
}
