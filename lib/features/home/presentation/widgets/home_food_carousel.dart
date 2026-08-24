import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../menu/domain/food_item.dart';
import 'food_item_card.dart';

/// Horizontal row of [FoodItemCard]s for specials or popular meals.
class HomeFoodCarousel extends StatelessWidget {
  const HomeFoodCarousel({
    super.key,
    required this.items,
    required this.onAdd,
    this.onItemTap,
    this.emptyLabel,
  });

  final List<FoodItem> items;
  final ValueChanged<FoodItem> onAdd;
  final ValueChanged<FoodItem>? onItemTap;
  final String? emptyLabel;

  static const double _rowHeight = 288;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text(
          emptyLabel ?? 'Nothing in this category yet.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    return SizedBox(
      height: _rowHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final item = items[index];
          return FoodItemCard(
            item: item,
            onAdd: () => onAdd(item),
            onTap: onItemTap == null ? null : () => onItemTap!(item),
          );
        },
      ),
    );
  }
}
