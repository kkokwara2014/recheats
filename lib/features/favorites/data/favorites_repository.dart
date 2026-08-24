import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/result.dart';
import '../../../services/firebase/firebase_bootstrap.dart';

/// Persists favorite menu item IDs for the signed-in customer.
abstract class FavoritesRepository {
  /// Empty list when signed out.
  Future<Result<List<String>>> fetchFavoriteIds();

  Future<Result<List<String>>> addFavorite(String foodItemId);

  Future<Result<List<String>>> removeFavorite(String foodItemId);
}

/// Firestore-backed favorites on `users/{uid}.favoriteItemIds`.
class FirebaseFavoritesRepository implements FavoritesRepository {
  FirebaseFavoritesRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth,
        _firestore = firestore;

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;

  FirebaseAuth get _firebaseAuth => _auth ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  @override
  Future<Result<List<String>>> fetchFavoriteIds() async {
    if (!_ensureFirebase()) {
      return const Success([]);
    }

    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return const Success([]);

      final doc = await _db.collection('users').doc(user.uid).get();
      return Success(_readIds(doc.data()));
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Fetch favorites failed: $error\n$stackTrace');
      }
      return Failure(
        UnknownAppException(
          'Could not load your favorites. Please try again.',
          cause: error,
          stackTrace: stackTrace,
        ),
        stackTrace,
      );
    }
  }

  @override
  Future<Result<List<String>>> addFavorite(String foodItemId) async {
    final gate = _requireUser();
    if (gate != null) return Failure(gate.$1, gate.$2);

    final id = foodItemId.trim();
    if (id.isEmpty) {
      return const Failure(ValidationException('That dish could not be saved.'));
    }

    final user = _firebaseAuth.currentUser!;

    try {
      final current = await _loadIds(user.uid);
      final next = [id, ...current.where((existing) => existing != id)];
      await _writeIds(user.uid, next);
      return Success(next);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Add favorite failed: $error\n$stackTrace');
      }
      return Failure(
        UnknownAppException(
          'Could not save that favorite. Please try again.',
          cause: error,
          stackTrace: stackTrace,
        ),
        stackTrace,
      );
    }
  }

  @override
  Future<Result<List<String>>> removeFavorite(String foodItemId) async {
    final gate = _requireUser();
    if (gate != null) return Failure(gate.$1, gate.$2);

    final user = _firebaseAuth.currentUser!;
    final id = foodItemId.trim();

    try {
      final current = await _loadIds(user.uid);
      final next = current.where((existing) => existing != id).toList();
      await _writeIds(user.uid, next);
      return Success(next);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Remove favorite failed: $error\n$stackTrace');
      }
      return Failure(
        UnknownAppException(
          'Could not update favorites. Please try again.',
          cause: error,
          stackTrace: stackTrace,
        ),
        stackTrace,
      );
    }
  }

  Future<List<String>> _loadIds(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return _readIds(doc.data());
  }

  Future<void> _writeIds(String uid, List<String> ids) {
    return _db.collection('users').doc(uid).set({
      'favoriteItemIds': ids,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  List<String> _readIds(Map<String, dynamic>? data) {
    final raw = data?['favoriteItemIds'];
    if (raw is! List) return const [];
    final ids = <String>[];
    for (final item in raw) {
      if (item is String) {
        final trimmed = item.trim();
        if (trimmed.isNotEmpty && !ids.contains(trimmed)) {
          ids.add(trimmed);
        }
      }
    }
    return ids;
  }

  (AppException, StackTrace?)? _requireUser() {
    if (!_ensureFirebase()) {
      return (
        const AuthException(
          'Favorites are unavailable right now. Try again later.',
        ),
        null,
      );
    }
    if (_firebaseAuth.currentUser == null) {
      return (
        const AuthException('Sign in to save favorites.'),
        null,
      );
    }
    return null;
  }

  bool _ensureFirebase() => FirebaseBootstrap.result.isReady;
}

/// In-memory favorites for widget tests and local demos without Firebase.
class FakeFavoritesRepository implements FavoritesRepository {
  FakeFavoritesRepository({List<String>? seed})
      : _ids = List<String>.from(seed ?? const []);

  final List<String> _ids;
  bool signedIn = true;
  bool failNext = false;

  @override
  Future<Result<List<String>>> fetchFavoriteIds() async {
    if (_shouldFail()) {
      return const Failure(
        UnknownAppException('Could not load your favorites.'),
      );
    }
    if (!signedIn) return const Success([]);
    return Success(List<String>.from(_ids));
  }

  @override
  Future<Result<List<String>>> addFavorite(String foodItemId) async {
    if (_shouldFail()) {
      return const Failure(
        UnknownAppException('Could not save that favorite.'),
      );
    }
    if (!signedIn) {
      return const Failure(AuthException('Sign in to save favorites.'));
    }
    final id = foodItemId.trim();
    _ids
      ..remove(id)
      ..insert(0, id);
    return Success(List<String>.from(_ids));
  }

  @override
  Future<Result<List<String>>> removeFavorite(String foodItemId) async {
    if (_shouldFail()) {
      return const Failure(
        UnknownAppException('Could not update favorites.'),
      );
    }
    if (!signedIn) {
      return const Failure(AuthException('Sign in to save favorites.'));
    }
    _ids.remove(foodItemId.trim());
    return Success(List<String>.from(_ids));
  }

  bool _shouldFail() {
    if (!failNext) return false;
    failNext = false;
    return true;
  }
}
