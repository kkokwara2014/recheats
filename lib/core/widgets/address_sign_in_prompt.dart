import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../routing/app_routes.dart';

/// Friendly guest gate for address screens (not a hard error).
class AddressSignInPrompt extends StatelessWidget {
  const AddressSignInPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 56,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                AppStrings.addressSignInRequiredTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                AppStrings.addressSignInRequiredBody,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: () => context.push(AppRoutes.login),
                child: const Text(AppStrings.signIn),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: () => context.push(AppRoutes.register),
                child: const Text(AppStrings.createAccount),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Asks a guest to sign in before opening the address form.
Future<void> promptSignInToSaveAddress(BuildContext context) async {
  final action = await showDialog<_AddressAuthAction>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text(AppStrings.addressSignInRequiredTitle),
        content: const Text(AppStrings.addressSignInRequiredBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, _AddressAuthAction.register),
            child: const Text(AppStrings.createAccount),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _AddressAuthAction.signIn),
            child: const Text(AppStrings.signIn),
          ),
        ],
      );
    },
  );

  if (!context.mounted || action == null) return;
  switch (action) {
    case _AddressAuthAction.signIn:
      context.push(AppRoutes.login);
    case _AddressAuthAction.register:
      context.push(AppRoutes.register);
  }
}

enum _AddressAuthAction { signIn, register }
