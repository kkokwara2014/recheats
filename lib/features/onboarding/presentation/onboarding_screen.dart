import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_routes.dart';
import '../../splash/application/startup_providers.dart';
import '../application/onboarding_providers.dart';
import 'widgets/onboarding_dots.dart';
import 'widgets/onboarding_page_view.dart';

/// Three-screen first-run intro. Completed once via Skip or Get Started.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;
  bool _finishing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLastPage {
    final pages = ref.read(onboardingPagesProvider);
    return _index >= pages.length - 1;
  }

  Future<void> _next() async {
    if (_isLastPage) {
      await _finish();
      return;
    }
    await _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);

    await ref.read(onboardingRepositoryProvider).markCompleted();
    if (!mounted) return;

    final session =
        await ref.read(sessionRepositoryProvider).currentSession();
    if (!mounted) return;

    if (session == null) {
      context.go(AppRoutes.welcome);
    } else if (!session.isActive) {
      context.go(AppRoutes.accountInactive);
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = ref.watch(onboardingPagesProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.xs,
                  right: AppSpacing.sm,
                ),
                child: TextButton(
                  onPressed: _finishing ? null : _finish,
                  child: const Text(AppStrings.onboardingSkip),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (context, index) {
                  return OnboardingPageView(page: pages[index]);
                },
              ),
            ),
            OnboardingDots(count: pages.length, index: _index),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _finishing ? null : _next,
                  child: Text(
                    _isLastPage
                        ? AppStrings.onboardingGetStarted
                        : AppStrings.onboardingNext,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
