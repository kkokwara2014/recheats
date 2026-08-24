/// Where the splash gate sends the user after session checks.
enum StartupDestination {
  /// No Firebase session — show welcome / sign-in entry.
  welcome,

  /// First-run intro not finished, or profile onboarding is incomplete.
  onboarding,

  /// Signed in but the customer account is deactivated.
  accountInactive,

  /// Signed in, onboarded, and active — enter the app.
  home,
}
