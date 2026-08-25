/// Customer registration payload for email/password sign-up.
class RegisterDetails {
  const RegisterDetails({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    this.phone,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String password;

  /// Contact number (E.164) — required for orders and future promotions.
  /// Not used for OTP auth in MVP.
  final String? phone;
}
