import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:recheats/app.dart';
import 'package:recheats/core/config/app_config.dart';
import 'package:recheats/core/constants/app_strings.dart';
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

  test('startup gate routes by session flags', () async {
    Future<void> expectDestination(
      SessionSnapshot? session,
      StartupDestination expected,
    ) async {
      final gate = StartupGate(FakeSessionRepository(session));
      expect(
        await gate.resolve(minDisplay: Duration.zero),
        expected,
      );
    }

    await expectDestination(null, StartupDestination.welcome);
    await expectDestination(
      const SessionSnapshot(
        uid: 'u1',
        onboardingCompleted: false,
        isActive: true,
      ),
      StartupDestination.onboarding,
    );
    await expectDestination(
      const SessionSnapshot(
        uid: 'u1',
        onboardingCompleted: true,
        isActive: false,
      ),
      StartupDestination.accountInactive,
    );
    await expectDestination(
      const SessionSnapshot(
        uid: 'u1',
        onboardingCompleted: true,
        isActive: true,
      ),
      StartupDestination.home,
    );
  }, timeout: const Timeout(Duration(seconds: 10)));

  testWidgets('splash shows RechEats brand then welcome when logged out', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionRepositoryProvider.overrideWith(
            (ref) => FakeSessionRepository(),
          ),
        ],
        child: const RecheatsApp(),
      ),
    );

    expect(find.text(AppStrings.appName), findsWidgets);

    await tester.pump(StartupGate.minDisplayDuration);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.welcomeBody), findsOneWidget);
  });
}
