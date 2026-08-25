/// Dialing metadata used by the phone number field.
class PhoneCountry {
  const PhoneCountry({
    required this.iso2,
    required this.name,
    required this.dialCode,
    required this.flag,
    required this.nationalNumberLength,
    this.exampleNational = '',
  });

  final String iso2;
  final String name;

  /// Digits only, no `+` (e.g. `1`, `234`).
  final String dialCode;
  final String flag;

  /// Expected count of national digits (no country code, no leading trunk `0`).
  final int nationalNumberLength;
  final String exampleNational;

  String get dialCodeLabel => '+$dialCode';

  /// Curated list — US first (Rockville, MD), then Nigeria and other common codes.
  static const List<PhoneCountry> all = [
    PhoneCountry(
      iso2: 'US',
      name: 'United States',
      dialCode: '1',
      flag: '🇺🇸',
      nationalNumberLength: 10,
      exampleNational: '3015551234',
    ),
    PhoneCountry(
      iso2: 'CA',
      name: 'Canada',
      dialCode: '1',
      flag: '🇨🇦',
      nationalNumberLength: 10,
      exampleNational: '4165551234',
    ),
    PhoneCountry(
      iso2: 'NG',
      name: 'Nigeria',
      dialCode: '234',
      flag: '🇳🇬',
      nationalNumberLength: 10,
      exampleNational: '8012345678',
    ),
    PhoneCountry(
      iso2: 'GB',
      name: 'United Kingdom',
      dialCode: '44',
      flag: '🇬🇧',
      nationalNumberLength: 10,
      exampleNational: '7911123456',
    ),
    PhoneCountry(
      iso2: 'GH',
      name: 'Ghana',
      dialCode: '233',
      flag: '🇬🇭',
      nationalNumberLength: 9,
      exampleNational: '241234567',
    ),
    PhoneCountry(
      iso2: 'KE',
      name: 'Kenya',
      dialCode: '254',
      flag: '🇰🇪',
      nationalNumberLength: 9,
      exampleNational: '712345678',
    ),
    PhoneCountry(
      iso2: 'ZA',
      name: 'South Africa',
      dialCode: '27',
      flag: '🇿🇦',
      nationalNumberLength: 9,
      exampleNational: '821234567',
    ),
    PhoneCountry(
      iso2: 'IN',
      name: 'India',
      dialCode: '91',
      flag: '🇮🇳',
      nationalNumberLength: 10,
      exampleNational: '9876543210',
    ),
    PhoneCountry(
      iso2: 'AU',
      name: 'Australia',
      dialCode: '61',
      flag: '🇦🇺',
      nationalNumberLength: 9,
      exampleNational: '412345678',
    ),
    PhoneCountry(
      iso2: 'FR',
      name: 'France',
      dialCode: '33',
      flag: '🇫🇷',
      nationalNumberLength: 9,
      exampleNational: '612345678',
    ),
    PhoneCountry(
      iso2: 'DE',
      name: 'Germany',
      dialCode: '49',
      flag: '🇩🇪',
      nationalNumberLength: 11,
      exampleNational: '15123456789',
    ),
    PhoneCountry(
      iso2: 'IE',
      name: 'Ireland',
      dialCode: '353',
      flag: '🇮🇪',
      nationalNumberLength: 9,
      exampleNational: '851234567',
    ),
    PhoneCountry(
      iso2: 'JM',
      name: 'Jamaica',
      dialCode: '1876',
      flag: '🇯🇲',
      nationalNumberLength: 7,
      exampleNational: '1234567',
    ),
  ];

  static PhoneCountry get defaultCountry => all.first;

  static PhoneCountry byIso2(String iso2) {
    final upper = iso2.toUpperCase();
    for (final country in all) {
      if (country.iso2 == upper) return country;
    }
    return defaultCountry;
  }
}

/// Helpers for national digits ↔ E.164 storage.
abstract final class PhoneNumberUtils {
  static String digitsOnly(String raw) =>
      raw.replaceAll(RegExp(r'\D'), '');

  /// Strips a leading trunk `0` common in local Nigerian / UK entry.
  static String normalizeNational(
    String raw, {
    required PhoneCountry country,
  }) {
    var digits = digitsOnly(raw);
    if (digits.startsWith('0') &&
        digits.length == country.nationalNumberLength + 1) {
      digits = digits.substring(1);
    }
    return digits;
  }

  static String? toE164({
    required PhoneCountry country,
    required String nationalRaw,
  }) {
    final national = normalizeNational(nationalRaw, country: country);
    if (national.isEmpty) return null;
    return '+${country.dialCode}$national';
  }

  /// Best-effort split of a stored phone into country + national digits.
  static ({PhoneCountry country, String national}) parseStored(String? raw) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) {
      return (country: PhoneCountry.defaultCountry, national: '');
    }

    final digits = digitsOnly(trimmed);
    if (trimmed.startsWith('+') || trimmed.startsWith('00')) {
      final sorted = [...PhoneCountry.all]
        ..sort((a, b) {
          final byLen = b.dialCode.length.compareTo(a.dialCode.length);
          if (byLen != 0) return byLen;
          // Prefer US over Canada for shared +1 numbers.
          if (a.iso2 == 'US') return -1;
          if (b.iso2 == 'US') return 1;
          return a.name.compareTo(b.name);
        });
      for (final country in sorted) {
        if (digits.startsWith(country.dialCode)) {
          final national = digits.substring(country.dialCode.length);
          if (national.length <= country.nationalNumberLength + 1) {
            return (
              country: country,
              national: normalizeNational(national, country: country),
            );
          }
        }
      }
    }

    // Bare local number — assume US (app's primary market).
    final us = PhoneCountry.byIso2('US');
    return (
      country: us,
      national: normalizeNational(digits, country: us),
    );
  }
}
