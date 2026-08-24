import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../checkout/presentation/widgets/checkout_order_summary.dart';
import '../domain/placed_order.dart';

/// Shown after successful payment with order summary and track CTA.
class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key, required this.order});

  final PlacedOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.orderConfirmedTitle),
        automaticallyImplyLeading: false,
      ),
      body: ResponsiveLayout(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 72,
                    color: AppColors.success,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    AppStrings.orderConfirmedHeadline,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    AppStrings.orderConfirmedNumber(order.displayCode),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    AppStrings.orderConfirmedThanks,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  CheckoutOrderSummary(
                    lines: order.lines,
                    title: AppStrings.orderConfirmedItems,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _ConfirmationDetailsCard(order: order),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      onPressed: () => context.push(
                        AppRoutes.orderTrack,
                        extra: order,
                      ),
                      child: const Text(AppStrings.trackOrder),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton(
                      onPressed: () => context.go(AppRoutes.home),
                      child: const Text(AppStrings.backToMenu),
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

class _ConfirmationDetailsCard extends StatelessWidget {
  const _ConfirmationDetailsCard({required this.order});

  final PlacedOrder order;

  @override
  Widget build(BuildContext context) {
    final fulfillmentValue = order.isPickup
        ? _pickupLabel(order)
        : _deliveryLabel(order);

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
            _DetailRow(
              label: AppStrings.orderTotal,
              value: order.formattedTotal,
              emphasize: true,
            ),
            const SizedBox(height: AppSpacing.sm),
            _DetailRow(
              label: AppStrings.orderConfirmedFulfillment,
              value: fulfillmentValue,
            ),
            if (order.timing.displayLabel.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              _DetailRow(
                label: AppStrings.orderTimingTitle,
                value: order.timing.displayLabel,
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            _DetailRow(
              label: AppStrings.orderConfirmedPrepTime,
              value: order.prepTimeLabel,
            ),
            const SizedBox(height: AppSpacing.sm),
            _DetailRow(
              label: AppStrings.orderConfirmedStatus,
              value: order.status.label,
            ),
          ],
        ),
      ),
    );
  }

  String _pickupLabel(PlacedOrder order) {
    final location = order.pickupLocation?.trim();
    if (location == null || location.isEmpty) {
      return AppStrings.fulfillmentPickup;
    }
    return '${AppStrings.fulfillmentPickup} · $location';
  }

  String _deliveryLabel(PlacedOrder order) {
    final address = order.delivery?.formattedAddress.trim() ?? '';
    if (address.isEmpty) return AppStrings.fulfillmentDelivery;
    return '${AppStrings.fulfillmentDelivery} · $address';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
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
    final labelStyle = theme.textTheme.bodyMedium?.copyWith(
      color: AppColors.textSecondary,
    );
    final valueStyle = emphasize
        ? theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          )
        : theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: labelStyle)),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: valueStyle,
          ),
        ),
      ],
    );
  }
}
