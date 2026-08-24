import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/result.dart';
import '../../../services/firebase/firebase_bootstrap.dart';
import '../domain/shop_fulfillment_settings.dart';

/// Reads and updates Rechael's pickup / delivery configuration.
abstract class ShopRepository {
  Future<Result<ShopFulfillmentSettings>> fetchFulfillmentSettings();

  Future<Result<ShopFulfillmentSettings>> saveFulfillmentSettings(
    ShopFulfillmentSettings settings,
  );
}

/// In-memory settings used until Firestore shop sync is seeded.
class MockShopRepository implements ShopRepository {
  MockShopRepository({ShopFulfillmentSettings? seed})
      : _settings = seed ?? ShopFulfillmentSettings.defaults;

  ShopFulfillmentSettings _settings;

  @override
  Future<Result<ShopFulfillmentSettings>> fetchFulfillmentSettings() async {
    return Success(_settings);
  }

  @override
  Future<Result<ShopFulfillmentSettings>> saveFulfillmentSettings(
    ShopFulfillmentSettings settings,
  ) async {
    if (!settings.hasAnyMethod) {
      return const Failure(
        ValidationException('Enable pickup, delivery, or both.'),
      );
    }
    if (settings.pickupEnabled && settings.pickupLocation.trim().isEmpty) {
      return const Failure(
        ValidationException('Add a pickup location customers can find.'),
      );
    }
    _settings = settings.copyWith(
      pickupLocation: settings.pickupLocation.trim(),
      deliveryFee: settings.deliveryFee < 0 ? 0 : settings.deliveryFee,
    );
    return Success(_settings);
  }
}

/// Firestore-backed shop settings (`shop/settings` document).
class FirebaseShopRepository implements ShopRepository {
  FirebaseShopRepository({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _db.collection('shop').doc('settings');

  @override
  Future<Result<ShopFulfillmentSettings>> fetchFulfillmentSettings() async {
    if (!_ensureFirebase()) {
      return const Success(ShopFulfillmentSettings.defaults);
    }

    try {
      final snapshot = await _doc.get();
      if (!snapshot.exists || snapshot.data() == null) {
        return const Success(ShopFulfillmentSettings.defaults);
      }
      return Success(ShopFulfillmentSettings.fromMap(snapshot.data()));
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Fetch shop settings failed: $error\n$stackTrace');
      }
      return Failure(
        UnknownAppException(
          'Could not load fulfillment settings. Please try again.',
          cause: error,
          stackTrace: stackTrace,
        ),
        stackTrace,
      );
    }
  }

  @override
  Future<Result<ShopFulfillmentSettings>> saveFulfillmentSettings(
    ShopFulfillmentSettings settings,
  ) async {
    if (!_ensureFirebase()) {
      return const Failure(
        UnknownAppException(
          'Fulfillment settings are unavailable right now. Try again later.',
        ),
      );
    }

    if (!settings.hasAnyMethod) {
      return const Failure(
        ValidationException('Enable pickup, delivery, or both.'),
      );
    }
    if (settings.pickupEnabled && settings.pickupLocation.trim().isEmpty) {
      return const Failure(
        ValidationException('Add a pickup location customers can find.'),
      );
    }

    final normalized = settings.copyWith(
      pickupLocation: settings.pickupLocation.trim(),
      deliveryFee: settings.deliveryFee < 0 ? 0 : settings.deliveryFee,
    );

    try {
      await _doc.set({
        ...normalized.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return Success(normalized);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Save shop settings failed: $error\n$stackTrace');
      }
      return Failure(
        UnknownAppException(
          'Could not save fulfillment settings. Please try again.',
          cause: error,
          stackTrace: stackTrace,
        ),
        stackTrace,
      );
    }
  }

  bool _ensureFirebase() => FirebaseBootstrap.result.isReady;
}

/// In-memory shop settings for widget tests.
class FakeShopRepository implements ShopRepository {
  FakeShopRepository({ShopFulfillmentSettings? seed})
      : _settings = seed ?? ShopFulfillmentSettings.defaults;

  ShopFulfillmentSettings _settings;
  bool failNext = false;

  @override
  Future<Result<ShopFulfillmentSettings>> fetchFulfillmentSettings() async {
    if (_shouldFail()) {
      return const Failure(
        UnknownAppException('Could not load fulfillment settings.'),
      );
    }
    return Success(_settings);
  }

  @override
  Future<Result<ShopFulfillmentSettings>> saveFulfillmentSettings(
    ShopFulfillmentSettings settings,
  ) async {
    if (_shouldFail()) {
      return const Failure(
        UnknownAppException('Could not save fulfillment settings.'),
      );
    }
    if (!settings.hasAnyMethod) {
      return const Failure(
        ValidationException('Enable pickup, delivery, or both.'),
      );
    }
    _settings = settings;
    return Success(_settings);
  }

  bool _shouldFail() {
    if (!failNext) return false;
    failNext = false;
    return true;
  }
}
