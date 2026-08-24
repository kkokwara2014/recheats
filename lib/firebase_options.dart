// File generated style placeholder for FlutterFire.
//
// Run the following when your Firebase project is ready:
//   dart pub global activate flutterfire_cli
//   flutterfire configure --project=<your-firebase-project-id>
//
// That command will overwrite this file with real platform options.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  /// Flip to `true` after `flutterfire configure` fills in real values.
  static const bool isConfigured = false;

  static FirebaseOptions get currentPlatform {
    if (!isConfigured) {
      throw UnsupportedError(
        'Firebase is not configured yet. Run `flutterfire configure`, '
        'set DefaultFirebaseOptions.isConfigured = true, then launch with '
        '`--dart-define=USE_FIREBASE=true`.',
      );
    }

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

  // Placeholder values — replaced by flutterfire configure.

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
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'recheats',
    storageBucket: 'recheats.appspot.com',
    iosBundleId: 'org.recheats',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'recheats',
    storageBucket: 'recheats.appspot.com',
  );
}