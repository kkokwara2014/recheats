/// RechEats customer support channels.
///
/// Override at build time with `--dart-define`, e.g.:
/// `--dart-define=SUPPORT_PHONE=+13015550100`
abstract final class AppContact {
  /// E.164 phone for `tel:` links (digits and optional leading +).
  static const String phoneE164 = String.fromEnvironment(
    'SUPPORT_PHONE',
    defaultValue: '+13015550100',
  );

  /// Display string shown under Call.
  static const String phoneDisplay = String.fromEnvironment(
    'SUPPORT_PHONE_DISPLAY',
    defaultValue: '(301) 555-0100',
  );

  static const String email = String.fromEnvironment(
    'SUPPORT_EMAIL',
    defaultValue: 'support@recheats.com',
  );

  /// WhatsApp number in international form without `+` or spaces.
  static const String whatsappNumber = String.fromEnvironment(
    'SUPPORT_WHATSAPP',
    defaultValue: '13015550100',
  );

  static Uri get callUri => Uri(scheme: 'tel', path: phoneE164);

  static Uri emailUri({String? subject, String? body}) {
    final params = <String, String>{
      if (subject != null && subject.isNotEmpty) 'subject': subject,
      if (body != null && body.isNotEmpty) 'body': body,
    };
    return Uri(
      scheme: 'mailto',
      path: email,
      query: params.isEmpty
          ? null
          : params.entries
              .map(
                (e) =>
                    '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
              )
              .join('&'),
    );
  }

  static Uri whatsappUri({String? message}) {
    return Uri.parse('https://wa.me/$whatsappNumber').replace(
      queryParameters: {
        if (message != null && message.isNotEmpty) 'text': message,
      },
    );
  }
}
