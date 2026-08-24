import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:recheats/app.dart';
import 'package:recheats/core/config/app_config.dart';
import 'package:recheats/core/constants/app_strings.dart';
import 'package:recheats/core/routing/app_router.dart';
import 'package:recheats/features/onboarding/application/onboarding_providers.dart';
import 'package:recheats/features/onboarding/data/onboarding_repository.dart';
import 'package:recheats/features/splash/application/startup_gate.dart';
import 'package:recheats/features/splash/application/startup_providers.dart';
import 'package:recheats/features/splash/data/session_repository.dart';
import 'package:recheats/features/splash/domain/session_snapshot.dart';
import 'package:recheats/features/splash/domain/startup_destination.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    PackageInfo.setMockInitialValues(
      appName: 'RechEats',
      packageName: 'org.recheats',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    await AppConfig.ensureInitialized();
  });

  test('startup gate routes by onboarding + session flags', () async {
    Future<void> expectDestination({
      required SessionSnapshot? session,
      required bool onboardingCompleted,
      required StartupDestination expected,
    }) async {
      final gate = StartupGate(
        sessions: FakeSessionRepository(session),
        onboarding: FakeOnboardingRepository(completed: onboardingCompleted),
      );
      expect(
        await gate.resolve(minDisplay: Duration.zero),
        expected,
      );
    }

    await expectDestination(
      session: null,
      onboardingCompleted: false,
      expected: StartupDestination.onboarding,
    );
    await expectDestination(
      session: null,
      onboardingCompleted: true,
      expected: StartupDestination.welcome,
    );
    await expectDestination(
      session: const SessionSnapshot(
        uid: 'u1',
        onboardingCompleted: false,
        isActive: true,
      ),
      onboardingCompleted: true,
      expected: StartupDestination.onboarding,
    );
    await expectDestination(
      session: const SessionSnapshot(
        uid: 'u1',
        onboardingCompleted: true,
        isActive: false,
      ),
      onboardingCompleted: true,
      expected: StartupDestination.accountInactive,
    );
    await expectDestination(
      session: const SessionSnapshot(
        uid: 'u1',
        onboardingCompleted: true,
        isActive: true,
      ),
      onboardingCompleted: true,
      expected: StartupDestination.home,
    );
  }, timeout: const Timeout(Duration(seconds: 10)));

  testWidgets('splash shows RechEats brand then onboarding on first launch', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionRepositoryProvider.overrideWith(
            (ref) => FakeSessionRepository(),
          ),
          onboardingRepositoryProvider.overrideWith(
            (ref) => FakeOnboardingRepository(completed: false),
          ),
        ],
        child: RecheatsApp(
          router: AppRouter.create(
            navigatorKey: GlobalKey<NavigatorState>(),
          ),
        ),
      ),
    );

    expect(find.text(AppStrings.appName), findsWidgets);

    await tester.pump(StartupGate.minDisplayDuration);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.onboardingPage1Title), findsOneWidget);
    expect(find.text(AppStrings.onboardingSkip), findsOneWidget);
    expect(find.text(AppStrings.onboardingNext), findsOneWidget);
  });

  testWidgets('splash goes to welcome when onboarding already done', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionRepositoryProvider.overrideWith(
            (ref) => FakeSessionRepository(),
          ),
          onboardingRepositoryProvider.overrideWith(
            (ref) => FakeOnboardingRepository(completed: true),
          ),
        ],
        child: RecheatsApp(
          router: AppRouter.create(
            navigatorKey: GlobalKey<NavigatorState>(),
          ),
        ),
      ),
    );

    await tester.pump(StartupGate.minDisplayDuration);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.welcomeBody), findsOneWidget);
  });

  testWidgets('onboarding Skip completes and opens welcome', (tester) async {
    final onboarding = FakeOnboardingRepository(completed: false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionRepositoryProvider.overrideWith(
            (ref) => FakeSessionRepository(),
          ),
          onboardingRepositoryProvider.overrideWith((ref) => onboarding),
        ],
        child: RecheatsApp(
          router: AppRouter.create(
            navigatorKey: GlobalKey<NavigatorState>(),
          ),
        ),
      ),
    );

    await tester.pump(StartupGate.minDisplayDuration);
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.onboardingSkip));
    await tester.pumpAndSettle();

    expect(onboarding.completed, isTrue);
    expect(find.text(AppStrings.welcomeBody), findsOneWidget);
  });
}
