import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/order_timeline.dart';
import '../../domain/placed_order.dart';

/// Vertical status stepper for pickup or delivery (no GPS).
class OrderStatusTimeline extends StatelessWidget {
  const OrderStatusTimeline({
    super.key,
    required this.order,
  });

  final PlacedOrder order;

  @override
  Widget build(BuildContext context) {
    if (order.isCancelled) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const Icon(Icons.cancel, color: AppColors.error),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  OrderStatus.cancelled.label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final steps = OrderTimeline.stepsFor(order.method);
    final activeIndex = OrderTimeline.activeIndex(order.status, order.method);

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
            for (var i = 0; i < steps.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.md),
              _StatusStep(
                label: steps[i].label,
                isActive: i <= activeIndex,
                isCurrent: i == activeIndex,
                isLast: i == steps.length - 1,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusStep extends StatelessWidget {
  const _StatusStep({
    required this.label,
    required this.isActive,
    required this.isCurrent,
    required this.isLast,
  });

  final String label;
  final bool isActive;
  final bool isCurrent;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isActive ? AppColors.primary : AppColors.border;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(
              isCurrent
                  ? Icons.radio_button_checked
                  : isActive
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
              color: color,
              size: 22,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 20,
                margin: const EdgeInsets.only(top: AppSpacing.xxs),
                color: isActive ? AppColors.primary : AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? theme.colorScheme.onSurface
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
