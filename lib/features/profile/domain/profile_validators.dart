/// Field checks for profile and US address forms (Maryland / Rockville service area).
abstract final class ProfileValidators {
  static const _usStateCodes = {
    'AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA', 'HI', 'ID',
    'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD', 'MA', 'MI', 'MN', 'MS',
    'MO', 'MT', 'NE', 'NV', 'NH', 'NJ', 'NM', 'NY', 'NC', 'ND', 'OH', 'OK',
    'OR', 'PA', 'RI', 'SC', 'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA', 'WV',
    'WI', 'WY', 'DC',
  };

  static final _usZip = RegExp(r'^\d{5}(-\d{4})?$');

  static String? requiredLabel(String? value, String emptyMessage) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return emptyMessage;
    return null;
  }

  static String? addressLabel(String? value) =>
      requiredLabel(value, 'Choose Home, Work, or Other');

  static String? street(String? value) =>
      requiredLabel(value, 'Enter a street address');

  static String? city(String? value) => requiredLabel(value, 'Enter a city');

  static String? state(String? value) {
    final trimmed = value?.trim().toUpperCase() ?? '';
    if (trimmed.isEmpty) return 'Enter a state';
    if (trimmed.length != 2 || !_usStateCodes.contains(trimmed)) {
      return 'Enter a valid US state (e.g. MD)';
    }
    return null;
  }

  static String? zip(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Enter a ZIP code';
    if (!_usZip.hasMatch(trimmed)) {
      return 'Enter a valid US ZIP (e.g. 20850)';
    }
    return null;
  }
}
