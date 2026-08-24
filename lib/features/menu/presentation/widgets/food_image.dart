import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/food_item.dart';

/// Resolves asset → network → branded placeholder for a menu item image.
class FoodImage extends StatelessWidget {
  const FoodImage({
    super.key,
    required this.item,
    this.fit = BoxFit.cover,
  });

  final FoodItem item;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final asset = item.imageAsset;
    if (asset != null && asset.isNotEmpty) {
      return Image.asset(
        asset,
        fit: fit,
        errorBuilder: (_, _, _) => const FoodImagePlaceholder(),
      );
    }

    final url = item.imageUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: fit,
        errorBuilder: (_, _, _) => const FoodImagePlaceholder(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const ColoredBox(
            color: AppColors.surfaceMuted,
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      );
    }

    return const FoodImagePlaceholder();
  }
}

class FoodImagePlaceholder extends StatelessWidget {
  const FoodImagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceMuted,
      child: Center(
        child: Icon(
          Icons.restaurant_menu_rounded,
          size: 40,
          color: AppColors.primary.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}
