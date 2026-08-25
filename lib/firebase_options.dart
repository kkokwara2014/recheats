// Generated for Firebase project `recheats`.
// Re-run: flutterfire configure --project=recheats

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  /// Real options for project `recheats` — keep `true` so Auth/Firestore boot.
  static const bool isConfigured = true;

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC1lX36c3mp6kEj5UXc5FFOKLuI3Jq-UjI',
    appId: '1:104738682294:web:a59d67b6ccf2a9a0f47d17',
    messagingSenderId: '104738682294',
    projectId: 'recheats',
    authDomain: 'recheats.firebaseapp.com',
    storageBucket: 'recheats.firebasestorage.app',
    measurementId: 'G-L645SGXRTS',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDP5xEh269rrkqpKi_IjqzYARjrgUsi7RM',
    appId: '1:104738682294:android:ed2d7c3434149b82f47d17',
    messagingSenderId: '104738682294',
    projectId: 'recheats',
    storageBucket: 'recheats.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD8OD6N7VTF8DBbEXaAHQ1t66tpPBptxkI',
    appId: '1:104738682294:ios:7d5b4fab55f11230f47d17',
    messagingSenderId: '104738682294',
    projectId: 'recheats',
    storageBucket: 'recheats.firebasestorage.app',
    iosBundleId: 'org.recheats',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD8OD6N7VTF8DBbEXaAHQ1t66tpPBptxkI',
    appId: '1:104738682294:ios:7d5b4fab55f11230f47d17',
    messagingSenderId: '104738682294',
    projectId: 'recheats',
    storageBucket: 'recheats.firebasestorage.app',
    iosBundleId: 'org.recheats',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyC1lX36c3mp6kEj5UXc5FFOKLuI3Jq-UjI',
    appId: '1:104738682294:web:a59d67b6ccf2a9a0f47d17',
    messagingSenderId: '104738682294',
    projectId: 'recheats',
    authDomain: 'recheats.firebaseapp.com',
    storageBucket: 'recheats.firebasestorage.app',
    measurementId: 'G-L645SGXRTS',
  );
}
