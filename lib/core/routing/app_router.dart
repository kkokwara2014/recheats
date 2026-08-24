import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/presentation/account_inactive_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/foundation/presentation/demo_states_screen.dart';
import '../../features/foundation/presentation/foundation_home_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import 'app_routes.dart';

/// App-wide [GoRouter] configuration.
abstract final class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  static final GoRouter config = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.accountInactive,
        name: 'account-inactive',
        builder: (context, state) => const AccountInactiveScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.foundation,
        name: 'foundation',
        builder: (context, state) => const FoundationHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.demoLoading,
        name: 'demo-loading',
        builder: (context, state) => const DemoStatesScreen(
          kind: DemoStateKind.loading,
        ),
      ),
      GoRoute(
        path: AppRoutes.demoEmpty,
        name: 'demo-empty',
        builder: (context, state) => const DemoStatesScreen(
          kind: DemoStateKind.empty,
        ),
      ),
      GoRoute(
        path: AppRoutes.demoError,
        name: 'demo-error',
        builder: (context, state) => const DemoStatesScreen(
          kind: DemoStateKind.error,
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.link_off, size: 48),
              const SizedBox(height: 12),
              Text(
                'Page not found',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(state.uri.toString()),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go(AppRoutes.welcome),
                child: const Text('Back to welcome'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
