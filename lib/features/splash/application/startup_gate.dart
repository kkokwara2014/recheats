import '../data/session_repository.dart';
import '../domain/session_snapshot.dart';
import '../domain/startup_destination.dart';
import '../../onboarding/data/onboarding_repository.dart';

/// Resolves the post-splash destination from onboarding + session checks.
class StartupGate {
  const StartupGate({
    required SessionRepository sessions,
    required OnboardingRepository onboarding,
  })  : _sessions = sessions,
        _onboarding = onboarding;

  final SessionRepository _sessions;
  final OnboardingRepository _onboarding;

  /// Minimum time the branded splash should remain visible.
  static const Duration minDisplayDuration = Duration(milliseconds: 1400);

  Future<StartupDestination> resolve({
    Duration minDisplay = minDisplayDuration,
  }) async {
    final sessionFuture = _sessions.currentSession();
    final onboardingFuture = _onboarding.isCompleted();

    if (minDisplay > Duration.zero) {
      await Future<void>.delayed(minDisplay);
    }

    final bool onboardingCompleted = await onboardingFuture;
    final SessionSnapshot? session = await sessionFuture;

    if (!onboardingCompleted) {
      return StartupDestination.onboarding;
    }
    if (session == null) {
      return StartupDestination.welcome;
    }
    if (!session.isActive) {
      return StartupDestination.accountInactive;
    }
    if (!session.onboardingCompleted) {
      return StartupDestination.onboarding;
    }
    return StartupDestination.home;
  }
}
