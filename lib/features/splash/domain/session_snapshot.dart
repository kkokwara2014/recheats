/// Lightweight session state used by the splash startup gate.
class SessionSnapshot {
  const SessionSnapshot({
    required this.uid,
    required this.onboardingCompleted,
    required this.isActive,
  });

  final String uid;
  final bool onboardingCompleted;
  final bool isActive;
}
