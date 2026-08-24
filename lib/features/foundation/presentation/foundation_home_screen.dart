import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/app_env.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../services/firebase/firebase_bootstrap.dart';

/// Module 1 landing screen confirming the foundation is wired.
class FoundationHomeScreen extends StatelessWidget {
  const FoundationHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = AppConfig.instance;
    final firebase = FirebaseBootstrap.result;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
      ),
      body: ResponsiveLayout(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          children: [
            Text(
              AppStrings.appName,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              AppStrings.tagline,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppStrings.locationHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              AppStrings.foundationTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              AppStrings.foundationBody,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _StatusCard(
              title: 'Environment',
              rows: [
                _StatusRow('Mode', AppEnv.label),
                _StatusRow('Version', config.versionLabel),
                _StatusRow('Package', config.packageName),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _StatusCard(
              title: 'Firebase',
              rows: [
                _StatusRow('Status', firebase.label),
                _StatusRow('USE_FIREBASE', AppEnv.useFirebase.toString()),
                _StatusRow('Analytics', AppEnv.enableAnalytics.toString()),
                _StatusRow('Crashlytics', AppEnv.enableCrashlytics.toString()),
                _StatusRow('App Check', AppEnv.enableAppCheck.toString()),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'State previews',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton(
                  onPressed: () => context.push(AppRoutes.demoLoading),
                  child: const Text('Loading'),
                ),
                OutlinedButton(
                  onPressed: () => context.push(AppRoutes.demoEmpty),
                  child: const Text('Empty'),
                ),
                OutlinedButton(
                  onPressed: () => context.push(AppRoutes.demoError),
                  child: const Text('Error'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.rows,
  });

  final String title;
  final List<_StatusRow> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        row.label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        row.value,
                        textAlign: TextAlign.end,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow {
  const _StatusRow(this.label, this.value);

  final String label;
  final String value;
}
