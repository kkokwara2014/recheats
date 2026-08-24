import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/routing/app_routes.dart';
import '../../auth/application/auth_providers.dart';

/// Shown when a signed-in account has been deactivated.
class AccountInactiveScreen extends ConsumerStatefulWidget {
  const AccountInactiveScreen({super.key});

  @override
  ConsumerState<AccountInactiveScreen> createState() =>
      _AccountInactiveScreenState();
}

class _AccountInactiveScreenState extends ConsumerState<AccountInactiveScreen> {
  bool _loggingOut = false;

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);

    final result = await ref.read(authRepositoryProvider).logout();
    if (!mounted) return;

    result.when(
      success: (_) => context.go(AppRoutes.welcome),
      failure: (error, _) {
        setState(() => _loggingOut = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.userMessage(error))),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(
                Icons.lock_outline,
                size: 56,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                AppStrings.accountInactiveTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppStrings.accountInactiveBody,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _loggingOut ? null : _logout,
                child: _loggingOut
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(AppStrings.logout),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
