import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_strings.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

class RecheatsApp extends ConsumerWidget {
  const RecheatsApp({
    super.key,
    this.router,
  });

  /// Optional router override (tests). Defaults to [AppRouter.config].
  final GoRouter? router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: router ?? AppRouter.config,
    );
  }
}
