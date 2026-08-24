/// Preset labels customers can assign to a saved delivery address.
enum AddressLabel {
  home,
  work,
  other;

  String get displayName => switch (this) {
        AddressLabel.home => 'Home',
        AddressLabel.work => 'Work',
        AddressLabel.other => 'Other',
      };

  /// Maps stored / free-text labels onto a preset. Unknown values become [other].
  static AddressLabel fromStored(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';
    return switch (normalized) {
      'home' => AddressLabel.home,
      'work' => AddressLabel.work,
      'other' => AddressLabel.other,
      _ => AddressLabel.other,
    };
  }
}
