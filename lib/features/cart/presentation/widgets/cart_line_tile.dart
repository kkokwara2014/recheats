import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/cart_line_item.dart';

/// One cart line: name, price, qty stepper, remove / modify / notes actions.
class CartLineTile extends StatelessWidget {
  const CartLineTile({
    super.key,
    required this.line,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
    required this.onModify,
    required this.onEditInstructions,
  });

  final CartLineItem line;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;
  final VoidCallback onModify;
  final VoidCallback onEditInstructions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detailParts = <String>[
      ...line.variationLabels,
      for (final addOn in line.addOns) addOn.name,
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    line.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  line.formattedLineTotal,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            if (detailParts.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                detailParts.join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (line.hasNotes) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                line.specialInstructions,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _QtyControl(
                  quantity: line.quantity,
                  onIncrease: onIncrease,
                  onDecrease: onDecrease,
                ),
                const Spacer(),
                TextButton(
                  onPressed: onEditInstructions,
                  child: Text(
                    line.hasNotes
                        ? AppStrings.editInstructions
                        : AppStrings.addInstructions,
                  ),
                ),
                TextButton(
                  onPressed: onModify,
                  child: const Text(AppStrings.modifyItem),
                ),
                IconButton(
                  tooltip: AppStrings.removeItem,
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: AppColors.error,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyControl extends StatelessWidget {
  const _QtyControl({
    required this.quantity,
    required this.onIncrease,
    required this.onDecrease,
  });

  final int quantity;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onDecrease,
            icon: Icon(
              quantity <= 1 ? Icons.delete_outline_rounded : Icons.remove_rounded,
              size: 20,
            ),
            tooltip: quantity <= 1
                ? AppStrings.removeItem
                : AppStrings.decreaseQuantity,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text(
              '$quantity',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: quantity >= 99 ? null : onIncrease,
            icon: const Icon(Icons.add_rounded, size: 20),
            tooltip: AppStrings.increaseQuantity,
          ),
        ],
      ),
    );
  }
}
