import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../shop/domain/fulfillment_method.dart';
import '../../../shop/domain/shop_fulfillment_settings.dart';

/// Pickup vs delivery choice — only shows methods Rechael has enabled.
class FulfillmentMethodSelector extends StatelessWidget {
  const FulfillmentMethodSelector({
    super.key,
    required this.settings,
    required this.selected,
    required this.onChanged,
  });

  final ShopFulfillmentSettings settings;
  final FulfillmentMethod? selected;
  final ValueChanged<FulfillmentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = <(FulfillmentMethod, String, IconData)>[
      if (settings.offersPickup)
        (FulfillmentMethod.pickup, AppStrings.fulfillmentPickup, Icons.storefront_outlined),
      if (settings.offersDelivery)
        (
          FulfillmentMethod.delivery,
          AppStrings.fulfillmentDelivery,
          Icons.delivery_dining_outlined,
        ),
    ];

    if (options.isEmpty) {
      return Text(
        AppStrings.fulfillmentNoneAvailable,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.fulfillmentSectionTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.xs),
          _MethodTile(
            label: options[i].$2,
            icon: options[i].$3,
            selected: selected == options[i].$1,
            onTap: () => onChanged(options[i].$1),
          ),
        ],
      ],
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected ? AppColors.surfaceMuted : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: selected ? AppColors.primary : AppColors.border,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
