import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/routing/app_router.dart';
import 'firebase_services.dart';

/// Registers the device FCM token on `users/{uid}` and shows foreground banners.
class PushNotificationController {
  PushNotificationController({
    MessagingService? messaging,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _messaging = messaging ?? const MessagingService(enabled: false),
        _auth = auth,
        _firestore = firestore;

  final MessagingService _messaging;
  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<IncomingPushMessage>? _foregroundSub;
  bool _started = false;
  String? _boundUid;
  String? _cachedToken;

  FirebaseAuth get _firebaseAuth => _auth ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  /// Call once after Firebase messaging is live (safe when messaging is disabled).
  Future<void> start() async {
    if (_started) return;
    _started = true;

    if (!_messaging.enabled) return;

    await _messaging.requestPermission();
    await _messaging.ensureAndroidNotificationChannel();

    _foregroundSub =
        _messaging.onForegroundMessage.listen(_showForegroundBanner);
    _tokenRefreshSub = _messaging.onTokenRefresh.listen((token) async {
      _cachedToken = token;
      final uid = _boundUid ?? _firebaseAuth.currentUser?.uid;
      if (uid != null) {
        await _persistToken(uid, token);
      }
    });

    _authSub = _firebaseAuth.authStateChanges().listen((user) async {
      if (user == null) {
        await _detachToken();
        return;
      }
      await syncForUser(user.uid);
    });

    final current = _firebaseAuth.currentUser;
    if (current != null) {
      await syncForUser(current.uid);
    }
  }

  /// Request permission (if needed) and store the current device token.
  Future<void> syncForUser(String userId) async {
    if (!_messaging.enabled) return;

    try {
      await _messaging.requestPermission();
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;

      if (_boundUid != null && _boundUid != userId && _cachedToken != null) {
        await _removeToken(_boundUid!, _cachedToken!);
      }

      _boundUid = userId;
      _cachedToken = token;
      await _persistToken(userId, token);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('FCM sync failed: $error\n$stackTrace');
      }
    }
  }

  /// Removes this device token from the user doc (call before sign-out).
  Future<void> clearForCurrentUser() async {
    await _detachToken();
  }

  Future<void> dispose() async {
    await _authSub?.cancel();
    await _tokenRefreshSub?.cancel();
    await _foregroundSub?.cancel();
    _authSub = null;
    _tokenRefreshSub = null;
    _foregroundSub = null;
    _started = false;
  }

  Future<void> _detachToken() async {
    final uid = _boundUid;
    final token = _cachedToken;
    _boundUid = null;
    _cachedToken = null;
    if (uid == null || token == null || token.isEmpty) return;
    await _removeToken(uid, token);
  }

  Future<void> _persistToken(String userId, String token) async {
    await _db.collection('users').doc(userId).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _removeToken(String userId, String token) async {
    try {
      await _db.collection('users').doc(userId).set({
        'fcmTokens': FieldValue.arrayRemove([token]),
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('FCM token remove failed: $error\n$stackTrace');
      }
    }
  }

  void _showForegroundBanner(IncomingPushMessage message) {
    final title = message.title ?? 'RechEats';
    final body = message.body;
    if (body == null || body.isEmpty) return;

    final context = AppRouter.rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text('$title: $body'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
