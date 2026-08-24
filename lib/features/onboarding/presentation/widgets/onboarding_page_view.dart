import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/onboarding_page.dart';

/// Single onboarding slide: illustration, title, and supporting copy.
class OnboardingPageView extends StatelessWidget {
  const OnboardingPageView({
    super.key,
    required this.page,
  });

  final OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}
