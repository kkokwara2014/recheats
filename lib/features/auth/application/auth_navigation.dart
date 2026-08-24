import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../onboarding/application/onboarding_providers.dart';
import '../../splash/application/startup_providers.dart';

/// Routes after a successful login or registration.
Future<void> navigateAfterAuth(WidgetRef ref, BuildContext context) async {
  final onboardingDone =
      await ref.read(onboardingRepositoryProvider).isCompleted();
  if (!context.mounted) return;

  if (!onboardingDone) {
    context.go(AppRoutes.onboarding);
    return;
  }

  final session = await ref.read(sessionRepositoryProvider).currentSession();
  if (!context.mounted) return;

  if (session == null) {
    // Auth succeeded but session lookup failed — still enter the app.
    context.go(AppRoutes.home);
    return;
  }
  if (!session.isActive) {
    context.go(AppRoutes.accountInactive);
    return;
  }
  if (!session.onboardingCompleted) {
    context.go(AppRoutes.onboarding);
    return;
  }
  context.go(AppRoutes.home);
}
