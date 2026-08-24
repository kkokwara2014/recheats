import 'notification_prefs.dart';
import 'saved_address.dart';

/// Customer account details shown and edited from the profile module.
class CustomerProfile {
  const CustomerProfile({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.photoUrl,
    this.addresses = const [],
    this.notifications = const NotificationPrefs(),
  });

  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? photoUrl;
  final List<SavedAddress> addresses;
  final NotificationPrefs notifications;

  String get displayName {
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? email : name;
  }

  String get initials {
    final first = firstName.trim();
    final last = lastName.trim();
    if (first.isNotEmpty && last.isNotEmpty) {
      return '${first[0]}${last[0]}'.toUpperCase();
    }
    if (first.isNotEmpty) return first[0].toUpperCase();
    if (email.isNotEmpty) return email[0].toUpperCase();
    return '?';
  }

  CustomerProfile copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? photoUrl,
    bool clearPhone = false,
    bool clearPhotoUrl = false,
    List<SavedAddress>? addresses,
    NotificationPrefs? notifications,
  }) {
    return CustomerProfile(
      uid: uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: clearPhone ? null : (phone ?? this.phone),
      photoUrl: clearPhotoUrl ? null : (photoUrl ?? this.photoUrl),
      addresses: addresses ?? this.addresses,
      notifications: notifications ?? this.notifications,
    );
  }
}
