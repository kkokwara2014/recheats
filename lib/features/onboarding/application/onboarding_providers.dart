import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../data/onboarding_repository.dart';
import '../domain/onboarding_page.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return SharedPreferencesOnboardingRepository();
});

final onboardingPagesProvider = Provider<List<OnboardingPage>>((ref) {
  return const [
    OnboardingPage(
      title: AppStrings.onboardingPage1Title,
      body: AppStrings.onboardingPage1Body,
      icon: Icons.restaurant_menu_rounded,
    ),
    OnboardingPage(
      title: AppStrings.onboardingPage2Title,
      body: AppStrings.onboardingPage2Body,
      icon: Icons.touch_app_rounded,
    ),
    OnboardingPage(
      title: AppStrings.onboardingPage3Title,
      body: AppStrings.onboardingPage3Body,
      icon: Icons.delivery_dining_rounded,
    ),
  ];
});
