import '../data/session_repository.dart';
import '../domain/session_snapshot.dart';
import '../domain/startup_destination.dart';

/// Resolves the post-splash destination from session checks.
class StartupGate {
  const StartupGate(this._sessions);

  final SessionRepository _sessions;

  /// Minimum time the branded splash should remain visible.
  static const Duration minDisplayDuration = Duration(milliseconds: 1400);

  Future<StartupDestination> resolve({
    Duration minDisplay = minDisplayDuration,
  }) async {
    final sessionFuture = _sessions.currentSession();
    if (minDisplay > Duration.zero) {
      await Future<void>.delayed(minDisplay);
    }
    final SessionSnapshot? session = await sessionFuture;

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
