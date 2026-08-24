import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/result.dart';
import '../../../services/firebase/firebase_bootstrap.dart';
import '../domain/order_feedback.dart';

/// Stores post-order ratings for Rechael (Firestore; not a public review feed).
abstract class FeedbackRepository {
  Future<bool> hasSubmitted(String orderId);

  /// Local-only: user dismissed the auto prompt without submitting.
  Future<bool> hasPromptDismissed(String orderId);

  Future<void> dismissPrompt(String orderId);

  Future<Result<OrderFeedback>> submit(OrderFeedback feedback);
}

class MockFeedbackRepository implements FeedbackRepository {
  MockFeedbackRepository({SharedPreferences? prefs}) : _prefs = prefs;

  final SharedPreferences? _prefs;
  final Map<String, OrderFeedback> _byOrderId = {};

  Future<SharedPreferences> _preferences() async =>
      _prefs ?? SharedPreferences.getInstance();

  @override
  Future<bool> hasSubmitted(String orderId) async {
    if (_byOrderId.containsKey(orderId)) return true;
    final prefs = await _preferences();
    return prefs.getBool(_submittedKey(orderId)) ?? false;
  }

  @override
  Future<bool> hasPromptDismissed(String orderId) async {
    final prefs = await _preferences();
    return prefs.getBool(_dismissedKey(orderId)) ?? false;
  }

  @override
  Future<void> dismissPrompt(String orderId) async {
    final prefs = await _preferences();
    await prefs.setBool(_dismissedKey(orderId), true);
  }

  @override
  Future<Result<OrderFeedback>> submit(OrderFeedback feedback) async {
    if (feedback.rating < 1 || feedback.rating > 5) {
      return const Failure(
        ValidationException('Choose a rating from 1 to 5 stars.'),
      );
    }
    _byOrderId[feedback.orderId] = feedback;
    final prefs = await _preferences();
    await prefs.setBool(_submittedKey(feedback.orderId), true);
    return Success(feedback);
  }
}

class FirebaseFeedbackRepository implements FeedbackRepository {
  FirebaseFeedbackRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    SharedPreferences? prefs,
  })  : _auth = auth,
        _firestore = firestore,
        _prefs = prefs;

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  final SharedPreferences? _prefs;

  FirebaseAuth get _firebaseAuth => _auth ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('order_feedback');

  Future<SharedPreferences> _preferences() async =>
      _prefs ?? SharedPreferences.getInstance();

  @override
  Future<bool> hasSubmitted(String orderId) async {
    final prefs = await _preferences();
    if (prefs.getBool(_submittedKey(orderId)) == true) return true;

    if (!_ensureFirebase()) return false;

    try {
      final snapshot = await _collection.doc(orderId).get();
      if (snapshot.exists) {
        await prefs.setBool(_submittedKey(orderId), true);
        return true;
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Feedback lookup failed: $error\n$stackTrace');
      }
    }
    return false;
  }

  @override
  Future<bool> hasPromptDismissed(String orderId) async {
    final prefs = await _preferences();
    return prefs.getBool(_dismissedKey(orderId)) ?? false;
  }

  @override
  Future<void> dismissPrompt(String orderId) async {
    final prefs = await _preferences();
    await prefs.setBool(_dismissedKey(orderId), true);
  }

  @override
  Future<Result<OrderFeedback>> submit(OrderFeedback feedback) async {
    if (feedback.rating < 1 || feedback.rating > 5) {
      return const Failure(
        ValidationException('Choose a rating from 1 to 5 stars.'),
      );
    }

    if (!_ensureFirebase()) {
      return const Failure(
        UnknownAppException(
          'Feedback is unavailable right now. Try again later.',
        ),
      );
    }

    try {
      final userId = feedback.userId ?? _firebaseAuth.currentUser?.uid;
      final saved = OrderFeedback(
        orderId: feedback.orderId,
        displayCode: feedback.displayCode,
        userId: userId,
        rating: feedback.rating,
        comment: feedback.comment.trim(),
        createdAt: feedback.createdAt,
      );

      await _collection.doc(feedback.orderId).set({
        ...saved.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      final prefs = await _preferences();
      await prefs.setBool(_submittedKey(feedback.orderId), true);

      return Success(saved);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Submit feedback failed: $error\n$stackTrace');
      }
      return Failure(
        UnknownAppException(
          'Could not send your feedback. Please try again.',
          cause: error,
          stackTrace: stackTrace,
        ),
        stackTrace,
      );
    }
  }

  bool _ensureFirebase() => FirebaseBootstrap.result.isReady;
}

class FakeFeedbackRepository implements FeedbackRepository {
  FakeFeedbackRepository();

  final Map<String, OrderFeedback> submitted = {};
  final Set<String> dismissed = {};

  @override
  Future<bool> hasSubmitted(String orderId) async =>
      submitted.containsKey(orderId);

  @override
  Future<bool> hasPromptDismissed(String orderId) async =>
      dismissed.contains(orderId);

  @override
  Future<void> dismissPrompt(String orderId) async {
    dismissed.add(orderId);
  }

  @override
  Future<Result<OrderFeedback>> submit(OrderFeedback feedback) async {
    if (feedback.rating < 1 || feedback.rating > 5) {
      return const Failure(
        ValidationException('Choose a rating from 1 to 5 stars.'),
      );
    }
    submitted[feedback.orderId] = feedback;
    return Success(feedback);
  }
}

String _submittedKey(String orderId) => 'order_feedback_submitted_$orderId';

String _dismissedKey(String orderId) => 'order_feedback_dismissed_$orderId';
