import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';

/// Dot indicators for the onboarding PageView.
class OnboardingDots extends StatelessWidget {
  const OnboardingDots({
    super.key,
    required this.count,
    required this.index,
  });

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final selected = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          width: selected ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
        );
      }),
    );
  }
}
