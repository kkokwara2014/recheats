import 'package:flutter/foundation.dart';

/// Outcome of Firebase bootstrap for the current process.
enum FirebaseBootstrapStatus {
  disabled,
  notConfigured,
  ready,
  failed,
}

class FirebaseBootstrapResult {
  const FirebaseBootstrapResult({
    required this.status,
    this.error,
  });

  final FirebaseBootstrapStatus status;
  final Object? error;

  bool get isReady => status == FirebaseBootstrapStatus.ready;

  String get label => switch (status) {
        FirebaseBootstrapStatus.disabled => 'Disabled (USE_FIREBASE=false)',
        FirebaseBootstrapStatus.notConfigured => 'Not configured',
        FirebaseBootstrapStatus.ready => 'Ready',
        FirebaseBootstrapStatus.failed => 'Failed',
      };
}

class AnalyticsService {
  const AnalyticsService({required this.enabled});

  final bool enabled;

  Future<void> logAppOpen() async {
    if (!enabled) return;
    // Wired when Firebase Analytics is active.
  }

  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    if (!enabled) return;
  }

  Future<void> setUserId(String? userId) async {
    if (!enabled) return;
  }
}

class CrashlyticsService {
  CrashlyticsService({required this.enabled});

  final bool enabled;

  Future<void> recordFlutterFatalError(FlutterErrorDetails details) async {
    if (!enabled) {
      if (kDebugMode) {
        debugPrint('Crashlytics (disabled): ${details.exceptionAsString()}');
      }
      return;
    }
  }

  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  }) async {
    if (!enabled) {
      if (kDebugMode) {
        debugPrint('Crashlytics (disabled): $error');
      }
      return;
    }
  }

  Future<void> setUserIdentifier(String userId) async {
    if (!enabled) return;
  }

  Future<void> log(String message) async {
    if (!enabled) return;
  }
}

class MessagingService {
  const MessagingService({required this.enabled});

  final bool enabled;

  Future<String?> getToken() async {
    if (!enabled) return null;
    return null;
  }

  Future<void> requestPermission() async {
    if (!enabled) return;
  }
}

class AppCheckService {
  const AppCheckService({required this.enabled});

  final bool enabled;

  Future<void> activate() async {
    if (!enabled) return;
  }
}
