import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_routes.dart';
import '../application/startup_providers.dart';
import '../domain/startup_destination.dart';
import 'widgets/brand_mark.dart';

/// Branded cold-start screen: animates the logo, then routes by session state.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _markScale;
  late final Animation<double> _markOpacity;
  late final Animation<double> _copyOpacity;
  late final Animation<Offset> _copySlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _markScale = Tween<double>(begin: 0.72, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.55, curve: Curves.easeOutBack),
      ),
    );
    _markOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.4, curve: Curves.easeOut),
      ),
    );
    _copyOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOut),
      ),
    );
    _copySlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final destination = await ref.read(startupGateProvider).resolve();
    if (!mounted) return;
    context.go(_pathFor(destination));
  }

  String _pathFor(StartupDestination destination) {
    return switch (destination) {
      StartupDestination.welcome => AppRoutes.welcome,
      StartupDestination.onboarding => AppRoutes.onboarding,
      StartupDestination.accountInactive => AppRoutes.accountInactive,
      StartupDestination.home => AppRoutes.home,
    };
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Opacity(
                    opacity: _markOpacity.value,
                    child: Transform.scale(
                      scale: _markScale.value,
                      child: const BrandMark(size: 104),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SlideTransition(
                    position: _copySlide,
                    child: FadeTransition(
                      opacity: _copyOpacity,
                      child: Column(
                        children: [
                          Text(
                            AppStrings.appName,
                            style: theme.textTheme.displaySmall?.copyWith(
                              color: AppColors.textOnPrimary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            AppStrings.tagline,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.textOnPrimary
                                  .withValues(alpha: 0.88),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
