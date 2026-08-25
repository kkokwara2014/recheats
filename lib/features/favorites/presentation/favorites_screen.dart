import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../cart/application/cart_providers.dart';
import '../../menu/domain/food_item.dart';
import '../../menu/presentation/widgets/food_image.dart';
import '../../profile/application/profile_providers.dart';
import '../application/favorites_providers.dart';
import 'widgets/favorite_button.dart';

/// Favourites tab: saved Nigerian dishes for quick reordering.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(customerProfileProvider);
    final favoritesAsync = ref.watch(favoriteFoodItemsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.favorites)),
      body: profileAsync.when(
        loading: () => const AppLoading(),
        error: (error, _) => AppErrorView(
          error: error,
          onRetry: () => invalidateCustomerProfile(ref),
        ),
        data: (profile) {
          if (profile == null) {
            return AppEmptyState(
              icon: Icons.favorite_outline,
              title: AppStrings.profileGuestTitle,
              message: AppStrings.favoritesSignInRequired,
              actionLabel: AppStrings.signIn,
              onAction: () => context.push(AppRoutes.login),
            );
          }

          return favoritesAsync.when(
            loading: () => const AppLoading(),
            error: (error, _) => AppErrorView(
              error: error,
              onRetry: () => invalidateFavorites(ref),
            ),
            data: (items) {
              if (items.isEmpty) {
                return AppEmptyState(
                  icon: Icons.favorite_outline,
                  title: AppStrings.favoritesEmptyTitle,
                  message: AppStrings.favoritesEmptyBody,
                  actionLabel: AppStrings.browseMenu,
                  onAction: () => context.go(AppRoutes.home),
                );
              }

              return ResponsiveLayout(
                child: RefreshIndicator(
                  onRefresh: () async {
                    invalidateFavorites(ref);
                    await ref.read(favoriteIdsProvider.future);
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _FavoriteTile(
                        item: item,
                        onOpen: () =>
                            context.push(AppRoutes.menuItemPath(item.id)),
                        onAdd: () => _onAdd(context, ref, item),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _onAdd(BuildContext context, WidgetRef ref, FoodItem item) {
    if (item.hasCustomizations || !item.isAvailable) {
      context.push(AppRoutes.menuItemPath(item.id));
      return;
    }

    ref.read(cartProvider.notifier).addItem(
          foodItemId: item.id,
          name: item.name,
          unitPrice: item.price,
          quantity: 1,
          imageAsset: item.imageAsset,
          imageUrl: item.imageUrl,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.addedToCartNamed(item.name)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({
    required this.item,
    required this.onOpen,
    required this.onAdd,
  });

  final FoodItem item;
  final VoidCallback onOpen;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: SizedBox(
                    width: 88,
                    height: 88,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.formattedPrice,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (!item.isAvailable)
                            Text(
                              AppStrings.unavailableLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          else
                            SizedBox(
                              height: 36,
                              child: FilledButton(
                                onPressed: onAdd,
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                  ),
                                  minimumSize: const Size(0, 36),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(AppStrings.addToOrder),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                FavoriteButton(
                  foodItemId: item.id,
                  foodItemName: item.name,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
