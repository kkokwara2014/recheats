import 'address_label.dart';

/// A US delivery address saved on the customer profile.
class SavedAddress {
  const SavedAddress({
    required this.id,
    required this.label,
    required this.line1,
    this.line2,
    required this.city,
    required this.state,
    required this.zip,
    this.instructions,
    this.isDefault = false,
  });

  final String id;

  /// Display label; typically [AddressLabel.displayName] (Home / Work / Other).
  final String label;
  final String line1;

  /// Apartment, suite, or unit.
  final String? line2;
  final String city;

  /// Two-letter US state code (e.g. MD).
  final String state;

  /// US ZIP or ZIP+4.
  final String zip;

  /// Gate codes, landmarks, leave-at-door notes, etc.
  final String? instructions;
  final bool isDefault;

  AddressLabel get addressLabel => AddressLabel.fromStored(label);

  String get singleLine {
    final second = (line2 == null || line2!.trim().isEmpty)
        ? ''
        : ', ${line2!.trim()}';
    return '$line1$second, $city, $state $zip';
  }

  SavedAddress copyWith({
    String? label,
    String? line1,
    String? line2,
    bool clearLine2 = false,
    String? city,
    String? state,
    String? zip,
    String? instructions,
    bool clearInstructions = false,
    bool? isDefault,
  }) {
    return SavedAddress(
      id: id,
      label: label ?? this.label,
      line1: line1 ?? this.line1,
      line2: clearLine2 ? null : (line2 ?? this.line2),
      city: city ?? this.city,
      state: state ?? this.state,
      zip: zip ?? this.zip,
      instructions: clearInstructions
          ? null
          : (instructions ?? this.instructions),
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'line1': line1,
        if (line2 != null && line2!.trim().isNotEmpty) 'line2': line2,
        'city': city,
        'state': state,
        'zip': zip,
        if (instructions != null && instructions!.trim().isNotEmpty)
          'instructions': instructions,
        'isDefault': isDefault,
      };

  factory SavedAddress.fromMap(Map<String, dynamic> map) {
    return SavedAddress(
      id: map['id'] as String? ?? '',
      label: map['label'] as String? ?? AddressLabel.other.displayName,
      line1: map['line1'] as String? ?? '',
      line2: map['line2'] as String?,
      city: map['city'] as String? ?? '',
      state: map['state'] as String? ?? '',
      zip: map['zip'] as String? ?? '',
      instructions: map['instructions'] as String?,
      isDefault: map['isDefault'] as bool? ?? false,
    );
  }
}
