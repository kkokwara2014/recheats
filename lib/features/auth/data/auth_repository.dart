import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/result.dart';
import '../../../services/firebase/firebase_bootstrap.dart';
import '../domain/register_details.dart';

/// Email/password customer auth for fast ordering.
abstract class AuthRepository {
  /// Creates the Auth user and a `users/{uid}` profile.
  ///
  /// [onboardingCompleted] mirrors the local first-run flag so splash routing
  /// stays consistent after sign-up.
  Future<Result<void>> register(
    RegisterDetails details, {
    bool onboardingCompleted = false,
  });

  Future<Result<void>> login({
    required String email,
    required String password,
  });

  Future<Result<void>> sendPasswordReset(String email);

  Future<Result<void>> logout();
}

/// Firebase Auth + `users/{uid}` profile write on registration.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth,
        _firestore = firestore;

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;

  FirebaseAuth get _firebaseAuth => _auth ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  @override
  Future<Result<void>> register(
    RegisterDetails details, {
    bool onboardingCompleted = false,
  }) async {
    if (!_ensureFirebase()) {
      return const Failure(
        AuthException('Sign-up is unavailable right now. Try again later.'),
      );
    }

    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: details.email.trim(),
        password: details.password,
      );
      final user = credential.user;
      if (user == null) {
        return const Failure(
          AuthException('Could not create your account. Please try again.'),
        );
      }

      final displayName =
          '${details.firstName.trim()} ${details.lastName.trim()}'.trim();
      await user.updateDisplayName(displayName);

      final phone = details.phone?.trim();

      await _db.collection('users').doc(user.uid).set({
        'firstName': details.firstName.trim(),
        'lastName': details.lastName.trim(),
        'email': details.email.trim().toLowerCase(),
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'onboardingCompleted': onboardingCompleted,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return const Success(null);
    } on FirebaseAuthException catch (error, stackTrace) {
      return Failure(_mapAuthException(error), stackTrace);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Register failed: $error\n$stackTrace');
      }
      return Failure(
        AuthException(
          'Could not create your account. Please try again.',
          cause: error,
          stackTrace: stackTrace,
        ),
        stackTrace,
      );
    }
  }

  @override
  Future<Result<void>> login({
    required String email,
    required String password,
  }) async {
    if (!_ensureFirebase()) {
      return const Failure(
        AuthException('Sign-in is unavailable right now. Try again later.'),
      );
    }

    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return const Success(null);
    } on FirebaseAuthException catch (error, stackTrace) {
      return Failure(_mapAuthException(error), stackTrace);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Login failed: $error\n$stackTrace');
      }
      return Failure(
        AuthException(
          'Could not sign in. Please try again.',
          cause: error,
          stackTrace: stackTrace,
        ),
        stackTrace,
      );
    }
  }

  @override
  Future<Result<void>> sendPasswordReset(String email) async {
    if (!_ensureFirebase()) {
      return const Failure(
        AuthException(
          'Password reset is unavailable right now. Try again later.',
        ),
      );
    }

    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
      return const Success(null);
    } on FirebaseAuthException catch (error, stackTrace) {
      return Failure(_mapAuthException(error), stackTrace);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Password reset failed: $error\n$stackTrace');
      }
      return Failure(
        AuthException(
          'Could not send reset email. Please try again.',
          cause: error,
          stackTrace: stackTrace,
        ),
        stackTrace,
      );
    }
  }

  @override
  Future<Result<void>> logout() async {
    if (!_ensureFirebase()) {
      return const Success(null);
    }

    try {
      await _firebaseAuth.signOut();
      return const Success(null);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Logout failed: $error\n$stackTrace');
      }
      return Failure(
        AuthException(
          'Could not sign out. Please try again.',
          cause: error,
          stackTrace: stackTrace,
        ),
        stackTrace,
      );
    }
  }

  bool _ensureFirebase() => FirebaseBootstrap.result.isReady;

  AuthException _mapAuthException(FirebaseAuthException error) {
    final message = switch (error.code) {
      'email-already-in-use' => 'An account already exists for that email.',
      'invalid-email' => 'Enter a valid email address.',
      'weak-password' => 'Choose a stronger password (at least 6 characters).',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' =>
        'Incorrect email or password.',
      'user-disabled' => 'This account has been disabled.',
      'too-many-requests' => 'Too many attempts. Please wait and try again.',
      'network-request-failed' => 'Check your connection and try again.',
      'operation-not-allowed' => 'Email sign-in is not enabled yet.',
      _ => 'Something went wrong. Please try again.',
    };
    return AuthException(message, cause: error);
  }
}

/// In-memory auth for widget tests and local demos without Firebase.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    Set<String>? registeredEmails,
    this.failNext = false,
  }) : registeredEmails = registeredEmails ?? <String>{};

  final Set<String> registeredEmails;
  bool failNext;
  bool signedIn = false;
  String? lastResetEmail;

  @override
  Future<Result<void>> register(
    RegisterDetails details, {
    bool onboardingCompleted = false,
  }) async {
    if (failNext) {
      failNext = false;
      return const Failure(AuthException('Could not create your account.'));
    }
    final email = details.email.trim().toLowerCase();
    if (registeredEmails.contains(email)) {
      return const Failure(
        AuthException('An account already exists for that email.'),
      );
    }
    registeredEmails.add(email);
    signedIn = true;
    return const Success(null);
  }

  @override
  Future<Result<void>> login({
    required String email,
    required String password,
  }) async {
    if (failNext) {
      failNext = false;
      return const Failure(AuthException('Incorrect email or password.'));
    }
    if (password.length < 6) {
      return const Failure(AuthException('Incorrect email or password.'));
    }
    signedIn = true;
    return const Success(null);
  }

  @override
  Future<Result<void>> sendPasswordReset(String email) async {
    if (failNext) {
      failNext = false;
      return const Failure(AuthException('Could not send reset email.'));
    }
    lastResetEmail = email.trim();
    return const Success(null);
  }

  @override
  Future<Result<void>> logout() async {
    signedIn = false;
    return const Success(null);
  }
}
