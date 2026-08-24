import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../services/firebase/firebase_bootstrap.dart';
import '../domain/session_snapshot.dart';

/// Reads the current auth + profile flags needed for splash routing.
abstract class SessionRepository {
  /// Returns null when the user is not signed in (or Firebase is unavailable).
  Future<SessionSnapshot?> currentSession();
}

/// Firebase Auth + Firestore-backed session lookup.
///
/// Profile fields on `users/{uid}`:
/// - `onboardingCompleted` (bool, default false)
/// - `isActive` (bool, default true)
class FirebaseSessionRepository implements SessionRepository {
  FirebaseSessionRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth,
        _firestore = firestore;

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;

  @override
  Future<SessionSnapshot?> currentSession() async {
    if (!FirebaseBootstrap.result.isReady) {
      return null;
    }

    try {
      final auth = _auth ?? FirebaseAuth.instance;
      final user = auth.currentUser;
      if (user == null) return null;

      final firestore = _firestore ?? FirebaseFirestore.instance;
      final doc = await firestore.collection('users').doc(user.uid).get();

      if (!doc.exists || doc.data() == null) {
        return SessionSnapshot(
          uid: user.uid,
          onboardingCompleted: false,
          isActive: true,
        );
      }

      final data = doc.data()!;
      return SessionSnapshot(
        uid: user.uid,
        onboardingCompleted: data['onboardingCompleted'] as bool? ?? false,
        isActive: data['isActive'] as bool? ?? true,
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Session lookup failed: $error\n$stackTrace');
      }
      // Fail closed to welcome so a bad profile read never blocks cold start.
      return null;
    }
  }
}

/// Deterministic session for widget tests and local demos.
class FakeSessionRepository implements SessionRepository {
  FakeSessionRepository([this.session]);

  final SessionSnapshot? session;

  @override
  Future<SessionSnapshot?> currentSession() async => session;
}
