import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/result.dart';
import '../../../services/firebase/firebase_bootstrap.dart';
import '../domain/customer_profile.dart';
import '../domain/notification_prefs.dart';
import '../domain/saved_address.dart';

/// Reads and updates the signed-in customer's profile.
abstract class ProfileRepository {
  /// Returns null when nobody is signed in.
  Future<Result<CustomerProfile?>> fetchProfile();

  Future<Result<CustomerProfile>> updateDetails({
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
  });

  Future<Result<CustomerProfile>> updatePhoto(Uint8List bytes);

  Future<Result<CustomerProfile>> clearPhoto();

  Future<Result<CustomerProfile>> saveAddress(SavedAddress address);

  Future<Result<CustomerProfile>> deleteAddress(String addressId);

  Future<Result<CustomerProfile>> updateNotifications(NotificationPrefs prefs);
}

/// Firestore + Auth + Storage-backed profile.
class FirebaseProfileRepository implements ProfileRepository {
  FirebaseProfileRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _auth = auth,
        _firestore = firestore,
        _storage = storage;

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  final FirebaseStorage? _storage;

  FirebaseAuth get _firebaseAuth => _auth ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;
  FirebaseStorage get _firebaseStorage => _storage ?? FirebaseStorage.instance;

  @override
  Future<Result<CustomerProfile?>> fetchProfile() async {
    if (!_ensureFirebase()) {
      return const Failure(
        AuthException('Profile is unavailable right now. Try again later.'),
      );
    }

    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return const Success(null);

      final doc = await _db.collection('users').doc(user.uid).get();
      final data = doc.data() ?? <String, dynamic>{};

      return Success(_mapProfile(user, data));
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Fetch profile failed: $error\n$stackTrace');
      }
      return Failure(
        UnknownAppException(
          'Could not load your profile. Please try again.',
          cause: error,
          stackTrace: stackTrace,
        ),
        stackTrace,
      );
    }
  }

  @override
  Future<Result<CustomerProfile>> updateDetails({
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
  }) async {
    final gate = _requireUser();
    if (gate != null) return Failure(gate.$1, gate.$2);

    final user = _firebaseAuth.currentUser!;
    final trimmedFirst = firstName.trim();
    final trimmedLast = lastName.trim();
    final trimmedEmail = email.trim().toLowerCase();
    final trimmedPhone = phone?.trim();
    final displayName = '$trimmedFirst $trimmedLast'.trim();

    try {
      await user.updateDisplayName(displayName);

      if (trimmedEmail != (user.email ?? '').toLowerCase()) {
        await user.verifyBeforeUpdateEmail(trimmedEmail);
      }

      await _db.collection('users').doc(user.uid).set({
        'firstName': trimmedFirst,
        'lastName': trimmedLast,
        'email': trimmedEmail,
        'phone': (trimmedPhone == null || trimmedPhone.isEmpty)
            ? FieldValue.delete()
            : trimmedPhone,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return fetchRequired(user.uid);
    } on FirebaseAuthException catch (error, stackTrace) {
      return Failure(_mapAuthException(error), stackTrace);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Update profile failed: $error\n$stackTrace');
      }
      return Failure(
        UnknownAppException(
          'Could not save your profile. Please try again.',
          cause: error,
          stackTrace: stackTrace,
        ),
        stackTrace,
      );
    }
  }

  @override
  Future<Result<CustomerProfile>> updatePhoto(Uint8List bytes) async {
    final gate = _requireUser();
    if (gate != null) return Failure(gate.$1, gate.$2);

    final user = _firebaseAuth.currentUser!;

    try {
      final ref = _firebaseStorage.ref('users/${user.uid}/profile.jpg');
      await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await ref.getDownloadURL();

      await user.updatePhotoURL(url);
      await _db.collection('users').doc(user.uid).set({
        'photoUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return fetchRequired(user.uid);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Update photo failed: $error\n$stackTrace');
      }
      return Failure(
        UnknownAppException(
          'Could not update your photo. Please try again.',
          cause: error,
          stackTrace: stackTrace,
        ),
        stackTrace,
      );
    }
  }

  @override
  Future<Result<CustomerProfile>> clearPhoto() async {
    final gate = _requireUser();
    if (gate != null) return Failure(gate.$1, gate.$2);

    final user = _firebaseAuth.currentUser!;

    try {
      try {
        await _firebaseStorage.ref('users/${user.uid}/profile.jpg').delete();
      } catch (_) {
        // Missing object is fine — still clear profile fields.
      }

      await user.updatePhotoURL(null);
      await _db.collection('users').doc(user.uid).set({
        'photoUrl': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return fetchRequired(user.uid);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Clear photo failed: $error\n$stackTrace');
      }
      return Failure(
        UnknownAppException(
          'Could not remove your photo. Please try again.',
          cause: error,
          stackTrace: stackTrace,
        ),
        stackTrace,
      );
    }
  }

  @override
  Future<Result<CustomerProfile>> saveAddress(SavedAddress address) async {
    final gate = _requireUser();
    if (gate != null) return Failure(gate.$1, gate.$2);

    final user = _firebaseAuth.currentUser!;

    try {
      final current = await fetchRequired(user.uid);
      return current.when(
        success: (profile) async {
          final list = _upsertAddress(profile.addresses, address);
          await _writeAddresses(user.uid, list);
          return Success(profile.copyWith(addresses: list));
        },
        failure: (error, stackTrace) async => Failure(error, stackTrace),
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Save address failed: $error\n$stackTrace');
      }
      return Failure(
        UnknownAppException(
          'Could not save that address. Please try again.',
          cause: error,
          stackTrace: stackTrace,
        ),
        stackTrace,
      );
    }
  }

  @override
  Future<Result<CustomerProfile>> deleteAddress(String addressId) async {
    final gate = _requireUser();
    if (gate != null) return Failure(gate.$1, gate.$2);

    final user = _firebaseAuth.currentUser!;

    try {
      final current = await fetchRequired(user.uid);
      return current.when(
        success: (profile) async {
          var list =
              profile.addresses.where((a) => a.id != addressId).toList();
          if (list.isNotEmpty && !list.any((a) => a.isDefault)) {
            list = [
              list.first.copyWith(isDefault: true),
              ...list.skip(1),
            ];
          }
          await _writeAddresses(user.uid, list);
          return Success(profile.copyWith(addresses: list));
        },
        failure: (error, stackTrace) async => Failure(error, stackTrace),
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Delete address failed: $error\n$stackTrace');
      }
      return Failure(
        UnknownAppException(
          'Could not delete that address. Please try again.',
          cause: error,
          stackTrace: stackTrace,
        ),
        stackTrace,
      );
    }
  }

  @override
  Future<Result<CustomerProfile>> updateNotifications(
    NotificationPrefs prefs,
  ) async {
    final gate = _requireUser();
    if (gate != null) return Failure(gate.$1, gate.$2);

    final user = _firebaseAuth.currentUser!;

    try {
      await _db.collection('users').doc(user.uid).set({
        'notifications': prefs.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return fetchRequired(user.uid);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Update notifications failed: $error\n$stackTrace');
      }
      return Failure(
        UnknownAppException(
          'Could not update notifications. Please try again.',
          cause: error,
          stackTrace: stackTrace,
        ),
        stackTrace,
      );
    }
  }

  Future<Result<CustomerProfile>> fetchRequired(String _) async {
    final result = await fetchProfile();
    return result.when(
      success: (profile) {
        if (profile == null) {
          return const Failure(
            AuthException('Sign in to manage your profile.'),
          );
        }
        return Success(profile);
      },
      failure: (error, stackTrace) => Failure(error, stackTrace),
    );
  }

  Future<void> _writeAddresses(String uid, List<SavedAddress> addresses) {
    return _db.collection('users').doc(uid).set({
      'addresses': addresses.map((a) => a.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  List<SavedAddress> _upsertAddress(
    List<SavedAddress> current,
    SavedAddress address,
  ) {
    final index = current.indexWhere((a) => a.id == address.id);
    final makeDefault = address.isDefault || (current.isEmpty && index < 0);
    final toSave = address.copyWith(isDefault: makeDefault);

    if (index >= 0) {
      return [
        for (final item in current)
          item.id == toSave.id
              ? toSave
              : item.copyWith(isDefault: makeDefault ? false : item.isDefault),
      ];
    }

    return [
      for (final item in current)
        item.copyWith(isDefault: makeDefault ? false : item.isDefault),
      toSave,
    ];
  }

  CustomerProfile _mapProfile(User user, Map<String, dynamic> data) {
    final addressesRaw = data['addresses'];
    final addresses = <SavedAddress>[];
    if (addressesRaw is List) {
      for (final item in addressesRaw) {
        if (item is Map<String, dynamic>) {
          addresses.add(SavedAddress.fromMap(item));
        } else if (item is Map) {
          addresses.add(
            SavedAddress.fromMap(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final firstName = (data['firstName'] as String?)?.trim() ?? '';
    final lastName = (data['lastName'] as String?)?.trim() ?? '';
    final email = (data['email'] as String?)?.trim().toLowerCase() ??
        (user.email ?? '');
    final phone = (data['phone'] as String?)?.trim();
    final photoUrl =
        (data['photoUrl'] as String?)?.trim() ?? user.photoURL;

    return CustomerProfile(
      uid: user.uid,
      firstName: firstName.isNotEmpty
          ? firstName
          : _splitDisplayName(user.displayName).$1,
      lastName: lastName.isNotEmpty
          ? lastName
          : _splitDisplayName(user.displayName).$2,
      email: email,
      phone: (phone == null || phone.isEmpty) ? null : phone,
      photoUrl: (photoUrl == null || photoUrl.isEmpty) ? null : photoUrl,
      addresses: addresses,
      notifications: NotificationPrefs.fromMap(
        data['notifications'] is Map<String, dynamic>
            ? data['notifications'] as Map<String, dynamic>
            : data['notifications'] is Map
                ? Map<String, dynamic>.from(data['notifications'] as Map)
                : null,
      ),
    );
  }

  (String, String) _splitDisplayName(String? displayName) {
    final parts = (displayName ?? '').trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return ('', '');
    if (parts.length == 1) return (parts.first, '');
    return (parts.first, parts.sublist(1).join(' '));
  }

  (AppException, StackTrace?)? _requireUser() {
    if (!_ensureFirebase()) {
      return (
        const AuthException(
          'Profile is unavailable right now. Try again later.',
        ),
        null,
      );
    }
    if (_firebaseAuth.currentUser == null) {
      return (
        const AuthException('Sign in to manage your profile.'),
        null,
      );
    }
    return null;
  }

  bool _ensureFirebase() => FirebaseBootstrap.result.isReady;

  AuthException _mapAuthException(FirebaseAuthException error) {
    final message = switch (error.code) {
      'email-already-in-use' => 'An account already exists for that email.',
      'invalid-email' => 'Enter a valid email address.',
      'requires-recent-login' =>
        'For security, sign out and sign back in before changing your email.',
      'network-request-failed' => 'Check your connection and try again.',
      _ => 'Could not save your profile. Please try again.',
    };
    return AuthException(message, cause: error);
  }
}

/// In-memory profile for widget tests and local demos without Firebase.
class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({CustomerProfile? seed})
      : _profile = seed ??
            const CustomerProfile(
              uid: 'fake-user',
              firstName: 'Rechael',
              lastName: 'Guest',
              email: 'guest@recheats.app',
              phone: '3015550100',
            );

  CustomerProfile? _profile;
  bool signedIn = true;
  bool failNext = false;

  @override
  Future<Result<CustomerProfile?>> fetchProfile() async {
    if (_shouldFail()) {
      return const Failure(UnknownAppException('Could not load your profile.'));
    }
    if (!signedIn) return const Success(null);
    return Success(_profile);
  }

  @override
  Future<Result<CustomerProfile>> updateDetails({
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
  }) async {
    if (_shouldFail()) {
      return const Failure(UnknownAppException('Could not save your profile.'));
    }
    if (!signedIn || _profile == null) {
      return const Failure(AuthException('Sign in to manage your profile.'));
    }
    final trimmedPhone = phone?.trim();
    _profile = _profile!.copyWith(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email.trim().toLowerCase(),
      phone: trimmedPhone,
      clearPhone: trimmedPhone == null || trimmedPhone.isEmpty,
    );
    return Success(_profile!);
  }

  @override
  Future<Result<CustomerProfile>> updatePhoto(Uint8List bytes) async {
    if (_shouldFail()) {
      return const Failure(UnknownAppException('Could not update your photo.'));
    }
    if (!signedIn || _profile == null) {
      return const Failure(AuthException('Sign in to manage your profile.'));
    }
    _profile = _profile!.copyWith(
      photoUrl: 'https://example.com/profile/${_profile!.uid}.jpg',
    );
    return Success(_profile!);
  }

  @override
  Future<Result<CustomerProfile>> clearPhoto() async {
    if (_shouldFail()) {
      return const Failure(UnknownAppException('Could not remove your photo.'));
    }
    if (!signedIn || _profile == null) {
      return const Failure(AuthException('Sign in to manage your profile.'));
    }
    _profile = _profile!.copyWith(clearPhotoUrl: true);
    return Success(_profile!);
  }

  @override
  Future<Result<CustomerProfile>> saveAddress(SavedAddress address) async {
    if (_shouldFail()) {
      return const Failure(
        UnknownAppException('Could not save that address.'),
      );
    }
    if (!signedIn || _profile == null) {
      return const Failure(AuthException('Sign in to manage your profile.'));
    }

    final list = _upsertAddresses(_profile!.addresses, address);
    _profile = _profile!.copyWith(addresses: list);
    return Success(_profile!);
  }

  List<SavedAddress> _upsertAddresses(
    List<SavedAddress> current,
    SavedAddress address,
  ) {
    final index = current.indexWhere((a) => a.id == address.id);
    final makeDefault = address.isDefault || (current.isEmpty && index < 0);
    final toSave = address.copyWith(isDefault: makeDefault);

    if (index >= 0) {
      return [
        for (final item in current)
          item.id == toSave.id
              ? toSave
              : item.copyWith(isDefault: makeDefault ? false : item.isDefault),
      ];
    }

    return [
      for (final item in current)
        item.copyWith(isDefault: makeDefault ? false : item.isDefault),
      toSave,
    ];
  }

  @override
  Future<Result<CustomerProfile>> deleteAddress(String addressId) async {
    if (_shouldFail()) {
      return const Failure(
        UnknownAppException('Could not delete that address.'),
      );
    }
    if (!signedIn || _profile == null) {
      return const Failure(AuthException('Sign in to manage your profile.'));
    }
    var list = _profile!.addresses.where((a) => a.id != addressId).toList();
    if (list.isNotEmpty && !list.any((a) => a.isDefault)) {
      list = [list.first.copyWith(isDefault: true), ...list.skip(1)];
    }
    _profile = _profile!.copyWith(addresses: list);
    return Success(_profile!);
  }

  @override
  Future<Result<CustomerProfile>> updateNotifications(
    NotificationPrefs prefs,
  ) async {
    if (_shouldFail()) {
      return const Failure(
        UnknownAppException('Could not update notifications.'),
      );
    }
    if (!signedIn || _profile == null) {
      return const Failure(AuthException('Sign in to manage your profile.'));
    }
    _profile = _profile!.copyWith(notifications: prefs);
    return Success(_profile!);
  }

  bool _shouldFail() {
    if (!failNext) return false;
    failNext = false;
    return true;
  }
}
