import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Top-level handler for FCM messages when the app is backgrounded / killed.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background isolates must initialize Firebase themselves.
  if (Firebase.apps.isEmpty && DefaultFirebaseOptions.isConfigured) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  if (kDebugMode) {
    debugPrint(
      'FCM background: ${message.messageId} '
      '${message.notification?.title} ${message.notification?.body}',
    );
  }
}
