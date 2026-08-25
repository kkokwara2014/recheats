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

  /// Required phone — accepts national digits or E.164.
  /// Prefer [PhoneNumberFormField] for country-aware length checks in the UI.
  static String? phoneRequired(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Enter your phone number';
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return 'Enter a valid phone number';
    return null;
  }

  /// Kept for older call sites; empty is allowed.
  static String? phoneOptional(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return phoneRequired(value);
  }
}
