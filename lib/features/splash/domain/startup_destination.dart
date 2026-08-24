/// Where the splash gate sends the user after session checks.
enum StartupDestination {
  /// No Firebase session — show welcome / sign-in entry.
  welcome,

  /// Signed in but profile onboarding is incomplete.
  onboarding,

  /// Signed in but the customer account is deactivated.
  accountInactive,

  /// Signed in, onboarded, and active — enter the app.
  home,
}
