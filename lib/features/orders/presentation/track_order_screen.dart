import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../checkout/presentation/widgets/checkout_order_summary.dart';
import '../../feedback/application/feedback_providers.dart';
import '../../feedback/domain/order_feedback.dart';
import '../../feedback/presentation/order_feedback_sheet.dart';
import '../application/order_providers.dart';
import '../domain/placed_order.dart';
import 'widgets/order_status_timeline.dart';

/// Status timeline for pickup or delivery (no GPS / rider map).
class TrackOrderScreen extends ConsumerStatefulWidget {
  const TrackOrderScreen({super.key, required this.order});

  final PlacedOrder order;

  @override
  ConsumerState<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends ConsumerState<TrackOrderScreen> {
  bool _autoPromptScheduled = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final watched = ref.watch(watchedOrderProvider(widget.order.id));
    final current = watched.asData?.value ?? widget.order;
    final subtitle = current.isDelivery
        ? AppStrings.trackOrderSubtitleDelivery
        : AppStrings.trackOrderSubtitlePickup;
    final feedbackEligible = OrderFeedback.isEligible(current.status);
    final feedbackSubmitted =
        ref.watch(orderFeedbackSubmittedProvider(current.id));

    if (feedbackEligible && !_autoPromptScheduled) {
      _autoPromptScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        maybePromptOrderFeedback(
          context: context,
          ref: ref,
          order: current,
        );
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.trackOrderTitle)),
      body: ResponsiveLayout(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              AppStrings.orderConfirmedNumber(current.displayCode),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              current.status.label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            OrderStatusTimeline(order: current),
            if (feedbackEligible)
              feedbackSubmitted.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (submitted) {
                  if (submitted) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.lg),
                    child: _FeedbackInviteCard(
                      onRate: () => showOrderFeedbackSheet(
                        context: context,
                        ref: ref,
                        order: current,
                        allowSkip: false,
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: AppSpacing.lg),
            _TrackDetailsCard(order: current),
            if (current.lines.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              CheckoutOrderSummary(
                lines: current.lines,
                title: AppStrings.orderConfirmedItems,
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text(AppStrings.backToMenu),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackInviteCard extends StatelessWidget {
  const _FeedbackInviteCard({required this.onRate});

  final VoidCallback onRate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.feedbackTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              AppStrings.feedbackCommentHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: onRate,
              child: const Text(AppStrings.feedbackRateCta),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackDetailsCard extends StatelessWidget {
  const _TrackDetailsCard({required this.order});

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
