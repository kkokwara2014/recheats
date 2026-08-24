import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../services/firebase/firebase_services.dart';
import 'app_exception.dart';

/// Global Flutter / zone error wiring for Module 1.
abstract final class ErrorHandler {
  static void install({
    required CrashlyticsService crashlytics,
  }) {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      unawaited(
        crashlytics.recordFlutterFatalError(details),
      );
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(crashlytics.recordError(error, stack, fatal: true));
      return true;
    };
  }

  static AppException map(Object error, [StackTrace? stackTrace]) {
    if (error is AppException) return error;

    final message = error.toString();
    if (message.contains('SocketException') ||
        message.contains('ClientException') ||
        message.contains('Failed host lookup')) {
      return NetworkException(
        'Unable to reach the network.',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    return UnknownAppException(
      'An unexpected error occurred.',
      cause: error,
      stackTrace: stackTrace,
    );
  }

  static String userMessage(Object error) {
    final mapped = map(error);
    return switch (mapped) {
      NetworkException() =>
        'Check your connection and try again.',
      AuthException() => mapped.message,
      NotFoundException() => mapped.message,
      ValidationException() => mapped.message,
      UnknownAppException() =>
        'Something went wrong. Please try again.',
    };
  }
}
