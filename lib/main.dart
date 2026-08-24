import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/errors/error_handler.dart';
import 'services/firebase/firebase_bootstrap.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    await AppConfig.ensureInitialized();
    await FirebaseBootstrap.initialize();

    ErrorHandler.install(crashlytics: FirebaseBootstrap.crashlytics);

    runApp(
      const ProviderScope(
        child: RecheatsApp(),
      ),
    );
  }, (error, stack) {
    unawaited(
      FirebaseBootstrap.crashlytics.recordError(error, stack, fatal: true),
    );
  });
}
