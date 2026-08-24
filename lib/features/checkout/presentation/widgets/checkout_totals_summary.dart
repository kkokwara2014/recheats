import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../cart/domain/cart_state.dart';
import '../../../shop/domain/fulfillment_method.dart';
import '../../../shop/domain/shop_fulfillment_settings.dart';
import '../../domain/checkout_state.dart';

/// Checkout totals that respect pickup (\$0) vs delivery fee.
class CheckoutTotalsSummary extends StatelessWidget {
  const CheckoutTotalsSummary({
    super.key,
    required this.cart,
    required this.checkout,
    required this.settings,
  });

  final CartState cart;
  final CheckoutState checkout;
  final ShopFulfillmentSettings settings;

  @override
  Widget build(BuildContext context) {
    final showDeliveryFee = checkout.method == FulfillmentMethod.delivery ||
        checkout.method == null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            _TotalRow(
              label: AppStrings.subtotal,
              value: cart.formattedSubtotal,
            ),
            if (showDeliveryFee) ...[
              const SizedBox(height: AppSpacing.xs),
              _TotalRow(
                label: AppStrings.deliveryFee,
                value: checkout.formattedDeliveryFee(settings),
              ),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Divider(height: 1),
            ),
            _TotalRow(
              label: AppStrings.orderTotal,
              value: checkout.formattedTotal(cart, settings),
              emphasize: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = emphasize
        ? theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          )
        : theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
          );
    final valueStyle = emphasize
        ? theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          )
        : theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          );

    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: valueStyle),
      ],
    );
  }
}
