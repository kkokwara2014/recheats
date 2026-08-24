/// Typed failures used across the app instead of raw exceptions in UI layers.
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause, this.stackTrace});

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType: $message';
}

final class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.cause,
    super.stackTrace,
  });
}

final class AuthException extends AppException {
  const AuthException(
    super.message, {
    super.cause,
    super.stackTrace,
  });
}

final class NotFoundException extends AppException {
  const NotFoundException(
    super.message, {
    super.cause,
    super.stackTrace,
  });
}

final class ValidationException extends AppException {
  const ValidationException(
    super.message, {
    super.cause,
    super.stackTrace,
  });
}

final class UnknownAppException extends AppException {
  const UnknownAppException(
    super.message, {
    super.cause,
    super.stackTrace,
  });
}
