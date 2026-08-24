import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../application/menu_providers.dart';
import '../domain/food_item.dart';
import 'widgets/food_image.dart';

/// Kitchen view: toggle Available / Unavailable without deleting dishes.
class ManageMenuScreen extends ConsumerWidget {
  const ManageMenuScreen({super.key});

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    FoodItem item,
    bool isAvailable,
  ) async {
    final result = await ref.read(menuRepositoryProvider).setAvailability(
          id: item.id,
          isAvailable: isAvailable,
        );

    if (!context.mounted) return;

    result.when(
      success: (_) {
        invalidateMenu(ref);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${item.name}: ${isAvailable ? AppStrings.availableLabel : AppStrings.unavailableLabel}',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      failure: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.userMessage(error)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAsync = ref.watch(menuItemsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.manageMenuTitle)),
      body: menuAsync.when(
        loading: () => const AppLoading(),
        error: (error, _) => AppErrorView(
          message: error.toString(),
          onRetry: () => invalidateMenu(ref),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              title: AppStrings.menuEmptyTitle,
              message: AppStrings.menuEmptyBody,
            );
          }

          return ResponsiveLayout(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];
                return _ManageMenuTile(
                  item: item,
                  onChanged: (value) => _toggle(context, ref, item, value),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ManageMenuTile extends StatelessWidget {
  const _ManageMenuTile({
    required this.item,
    required this.onChanged,
  });

  final FoodItem item;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: SizedBox(
              width: 64,
              height: 64,
              child: FoodImage(item: item),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${item.formattedPrice} · ${item.category.label}'
                  '${item.preparationLabel.isEmpty ? '' : ' · ${item.preparationLabel}'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (item.variationGroups.isNotEmpty ||
                    item.addOns.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    [
                      if (item.variationGroups.isNotEmpty)
                        '${item.variationGroups.length} variation'
                            '${item.variationGroups.length == 1 ? '' : 's'}',
                      if (item.addOns.isNotEmpty)
                        '${item.addOns.length} add-on'
                            '${item.addOns.length == 1 ? '' : 's'}',
                    ].join(' · '),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.isAvailable
                      ? AppStrings.availableLabel
                      : AppStrings.unavailableLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: item.isAvailable
                        ? AppColors.success
                        : AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: item.isAvailable,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
