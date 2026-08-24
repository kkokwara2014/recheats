/// Customer delivery fields collected at checkout (no rider assignment).
class DeliveryDetails {
  const DeliveryDetails({
    this.savedAddressId,
    this.streetAddress = '',
    this.apartmentUnit = '',
    this.city = '',
    this.state = '',
    this.zip = '',
    this.instructions = '',
  });

  final String? savedAddressId;
  final String streetAddress;
  final String apartmentUnit;
  final String city;
  final String state;
  final String zip;
  final String instructions;

  String get formattedAddress {
    final unit = apartmentUnit.trim();
    final unitPart = unit.isEmpty ? '' : ', $unit';
    final locality = [
      city.trim(),
      '${state.trim()} ${zip.trim()}'.trim(),
    ].where((part) => part.isNotEmpty).join(', ');
    final street = '${streetAddress.trim()}$unitPart';
    if (street.isEmpty) return locality;
    if (locality.isEmpty) return street;
    return '$street, $locality';
  }

  bool get hasStreet => streetAddress.trim().isNotEmpty;

  bool get isComplete =>
      streetAddress.trim().isNotEmpty &&
      city.trim().isNotEmpty &&
      state.trim().isNotEmpty &&
      zip.trim().isNotEmpty;

  DeliveryDetails copyWith({
    String? savedAddressId,
    bool clearSavedAddressId = false,
    String? streetAddress,
    String? apartmentUnit,
    String? city,
    String? state,
    String? zip,
    String? instructions,
  }) {
    return DeliveryDetails(
      savedAddressId:
          clearSavedAddressId ? null : (savedAddressId ?? this.savedAddressId),
      streetAddress: streetAddress ?? this.streetAddress,
      apartmentUnit: apartmentUnit ?? this.apartmentUnit,
      city: city ?? this.city,
      state: state ?? this.state,
      zip: zip ?? this.zip,
      instructions: instructions ?? this.instructions,
    );
  }

  Map<String, dynamic> toMap() => {
        if (savedAddressId != null) 'savedAddressId': savedAddressId,
        'streetAddress': streetAddress.trim(),
        if (apartmentUnit.trim().isNotEmpty)
          'apartmentUnit': apartmentUnit.trim(),
        'city': city.trim(),
        'state': state.trim(),
        'zip': zip.trim(),
        if (instructions.trim().isNotEmpty)
          'instructions': instructions.trim(),
        'formattedAddress': formattedAddress,
      };

  factory DeliveryDetails.fromMap(Map<String, dynamic> map) {
    return DeliveryDetails(
      savedAddressId: map['savedAddressId'] as String?,
      streetAddress: map['streetAddress'] as String? ?? '',
      apartmentUnit: map['apartmentUnit'] as String? ?? '',
      city: map['city'] as String? ?? '',
      state: map['state'] as String? ?? '',
      zip: map['zip'] as String? ?? '',
      instructions: map['instructions'] as String? ?? '',
    );
  }
}
