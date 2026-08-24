import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';

/// Full-screen or inline loading indicator with optional message.
class AppLoading extends StatelessWidget {
  const AppLoading({
    super.key,
    this.message = AppStrings.loadingDefault,
    this.compact = false,
  });

  final String? message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final indicator = const CircularProgressIndicator();

    if (compact) {
      return Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: indicator,
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            indicator,
            if (message != null && message!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Lightweight overlay for blocking actions.
class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({
    super.key,
    required this.visible,
    required this.child,
    this.message,
  });

  final bool visible;
  final Widget child;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (visible)
          Positioned.fill(
            child: ColoredBox(
              color: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.35),
              child: AppLoading(message: message),
            ),
          ),
      ],
    );
  }
}
