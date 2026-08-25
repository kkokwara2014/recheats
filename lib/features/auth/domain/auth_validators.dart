/// Lightweight field checks for auth forms (UI + repository).
abstract final class AuthValidators {
  static final RegExp _email = RegExp(
    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
  );

  static String? firstName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Enter your first name';
    return null;
  }

  static String? lastName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Enter your last name';
    return null;
  }

  static String? email(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Enter your email';
    if (!_email.hasMatch(trimmed)) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    final raw = value ?? '';
    if (raw.isEmpty) return 'Enter a password';
    if (raw.length < 6) return 'Use at least 6 characters';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    final raw = value ?? '';
    if (raw.isEmpty) return 'Confirm your password';
    if (raw != password) return 'Passwords do not match';
    return null;
  }

  /// Phone is optional for MVP — validate only when the user typed something.
  static String? phoneOptional(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    final digits = trimmed.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.length < 10) return 'Enter a valid phone number';
    return null;
  }
}
