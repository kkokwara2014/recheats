import 'package:flutter/material.dart';

/// One page in the first-run onboarding carousel.
class OnboardingPage {
  const OnboardingPage({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;
}
