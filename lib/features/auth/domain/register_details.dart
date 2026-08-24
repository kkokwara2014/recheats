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

  /// Optional contact number — collected for orders, not used for OTP auth.
  final String? phone;
}
