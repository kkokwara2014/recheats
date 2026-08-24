import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../application/favorites_providers.dart';

/// Heart control for saving a meal to My Favorites.
class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({
    super.key,
    required this.foodItemId,
    this.foodItemName,
    this.overlay = false,
  });

  final String foodItemId;
  final String? foodItemName;

  /// Soft circular backdrop for use on top of meal images.
  final bool overlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idsAsync = ref.watch(favoriteIdsProvider);
    final isFavorite = idsAsync.maybeWhen(
      data: (ids) => ids.contains(foodItemId),
      orElse: () => false,
    );

    final icon = Icon(
      isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      color: isFavorite ? AppColors.error : null,
    );

    final button = IconButton(
      tooltip: isFavorite
          ? AppStrings.removeFromFavorites
          : AppStrings.addToFavorites,
      onPressed: () => toggleFavorite(
        context: context,
        ref: ref,
        foodItemId: foodItemId,
        foodItemName: foodItemName,
      ),
      icon: icon,
    );

    if (!overlay) return button;

    return Material(
      color: AppColors.surface.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: button,
    );
  }
}
