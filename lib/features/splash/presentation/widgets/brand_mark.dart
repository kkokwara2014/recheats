import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Circular RechEats brand mark used on the splash screen.
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 96,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.textOnPrimary.withValues(alpha: 0.12),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.85),
            width: size * 0.035,
          ),
        ),
        child: Center(
          child: Text(
            'R',
            style: TextStyle(
              color: AppColors.textOnPrimary,
              fontSize: size * 0.48,
              fontWeight: FontWeight.w700,
              height: 1,
              letterSpacing: -1,
            ),
          ),
        ),
      ),
    );
  }
}
