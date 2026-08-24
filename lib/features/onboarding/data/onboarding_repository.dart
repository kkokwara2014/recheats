import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/firebase/firebase_bootstrap.dart';

/// Persists first-run onboarding completion so the flow appears only once.
abstract class OnboardingRepository {
  Future<bool> isCompleted();

  /// Marks onboarding done locally, and on the user profile when signed in.
  Future<void> markCompleted();
}

class SharedPreferencesOnboardingRepository implements OnboardingRepository {
  SharedPreferencesOnboardingRepository({
    SharedPreferences? prefs,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _prefs = prefs,
        _auth = auth,
        _firestore = firestore;

  static const String _key = 'onboarding_completed';

  final SharedPreferences? _prefs;
  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;

  Future<SharedPreferences> _preferences() async {
    return _prefs ?? SharedPreferences.getInstance();
  }

  @override
  Future<bool> isCompleted() async {
    final prefs = await _preferences();
    return prefs.getBool(_key) ?? false;
  }

  @override
  Future<void> markCompleted() async {
    final prefs = await _preferences();
    await prefs.setBool(_key, true);
    await _syncProfileIfSignedIn();
  }

  Future<void> _syncProfileIfSignedIn() async {
    if (!FirebaseBootstrap.result.isReady) return;

    try {
      final auth = _auth ?? FirebaseAuth.instance;
      final user = auth.currentUser;
      if (user == null) return;

      final firestore = _firestore ?? FirebaseFirestore.instance;
      await firestore.collection('users').doc(user.uid).set(
        {'onboardingCompleted': true},
        SetOptions(merge: true),
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Onboarding profile sync failed: $error\n$stackTrace');
      }
    }
  }
}

/// Deterministic onboarding flag for widget tests and local demos.
class FakeOnboardingRepository implements OnboardingRepository {
  FakeOnboardingRepository({this.completed = false});

  bool completed;

  @override
  Future<bool> isCompleted() async => completed;

  @override
  Future<void> markCompleted() async {
    completed = true;
  }
}
