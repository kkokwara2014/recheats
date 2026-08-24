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
import '../../feedback/application/feedback_providers.dart';
import '../../feedback/domain/order_feedback.dart';
import '../../feedback/presentation/order_feedback_sheet.dart';
import '../../shop/domain/fulfillment_method.dart';
import '../application/order_providers.dart';
import '../domain/order_timeline.dart';
import '../domain/placed_order.dart';

/// Profile → Order history: current and previous orders with Order Again.
class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(recentOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.orderHistory)),
      body: ordersAsync.when(
        loading: () => const AppLoading(),
        error: (error, _) => AppErrorView(
          error: error,
          onRetry: () => invalidateRecentOrders(ref),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return AppEmptyState(
              icon: Icons.receipt_long_outlined,
              title: AppStrings.orderHistoryEmptyTitle,
              message: AppStrings.orderHistoryEmptyBody,
              actionLabel: AppStrings.browseMenu,
              onAction: () => context.go(AppRoutes.home),
            );
          }

          final current = orders
              .where((order) => !OrderTimeline.isTerminal(order.status))
              .toList(growable: false);
          final previous = orders
              .where((order) => OrderTimeline.isTerminal(order.status))
              .toList(growable: false);

          return ResponsiveLayout(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(recentOrdersProvider);
                await ref.read(recentOrdersProvider.future);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  if (current.isNotEmpty) ...[
                    _SectionTitle(
                      title: current.length == 1
                          ? AppStrings.currentOrder
                          : AppStrings.currentOrders,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (var i = 0; i < current.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.sm),
                      _OrderHistoryCard(
                        order: current[i],
                        showTrack: true,
                        onOrderAgain: () => _orderAgain(context, ref, current[i]),
                        onTrack: () => context.push(
                          AppRoutes.orderTrack,
                          extra: current[i],
                        ),
                      ),
                    ],
                    if (previous.isNotEmpty)
                      const SizedBox(height: AppSpacing.xl),
                  ],
                  if (previous.isNotEmpty) ...[
                    const _SectionTitle(title: AppStrings.previousOrders),
                    const SizedBox(height: AppSpacing.sm),
                    for (var i = 0; i < previous.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.sm),
                      _OrderHistoryCard(
                        order: previous[i],
                        showTrack: false,
                        onOrderAgain: () =>
                            _orderAgain(context, ref, previous[i]),
                        onOpen: () => context.push(
                          AppRoutes.orderTrack,
                          extra: previous[i],
                        ),
                        onShareFeedback:
                            OrderFeedback.isEligible(previous[i].status)
                                ? () => showOrderFeedbackSheet(
                                      context: context,
                                      ref: ref,
                                      order: previous[i],
                                      allowSkip: false,
                                    )
                                : null,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _orderAgain(BuildContext context, WidgetRef ref, PlacedOrder order) {
    if (order.lines.isEmpty) return;
    ref.read(cartProvider.notifier).addFromOrder(order.lines);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.orderAgainAdded)),
    );
    context.push(AppRoutes.cart);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _OrderHistoryCard extends ConsumerWidget {
  const _OrderHistoryCard({
    required this.order,
    required this.showTrack,
    required this.onOrderAgain,
    this.onTrack,
    this.onOpen,
    this.onShareFeedback,
  });

  final PlacedOrder order;
  final bool showTrack;
  final VoidCallback onOrderAgain;
  final VoidCallback? onTrack;
  final VoidCallback? onOpen;
  final VoidCallback? onShareFeedback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final fulfillment = order.method == FulfillmentMethod.pickup
        ? AppStrings.fulfillmentPickup
        : AppStrings.fulfillmentDelivery;
    final feedbackSubmitted = onShareFeedback == null
        ? const AsyncValue<bool>.data(true)
        : ref.watch(orderFeedbackSubmittedProvider(order.id));
    final showFeedback = onShareFeedback != null &&
        !(feedbackSubmitted.asData?.value ?? true);

    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onOpen ?? onTrack,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.orderConfirmedNumber(order.displayCode),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _StatusChip(status: order.status),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _MetaRow(
                label: AppStrings.orderHistoryDate,
                value: order.formattedCreatedAt,
              ),
              const SizedBox(height: AppSpacing.xs),
              _MetaRow(
                label: AppStrings.orderHistoryItems,
                value: order.itemsSummary.isEmpty
                    ? '—'
                    : order.itemsSummary,
              ),
              const SizedBox(height: AppSpacing.xs),
              _MetaRow(
                label: AppStrings.orderTotal,
                value: order.formattedTotal,
                emphasize: true,
              ),
              const SizedBox(height: AppSpacing.xs),
              _MetaRow(
                label: AppStrings.orderConfirmedFulfillment,
                value: fulfillment,
              ),
              const SizedBox(height: AppSpacing.xs),
              _MetaRow(
                label: AppStrings.orderHistoryStatus,
                value: order.status.label,
              ),
              const SizedBox(height: AppSpacing.md),
              if (showTrack && onTrack != null) ...[
                FilledButton(
                  onPressed: onTrack,
                  child: const Text(AppStrings.trackOrder),
                ),
                const SizedBox(height: AppSpacing.xs),
                OutlinedButton(
                  onPressed: onOrderAgain,
                  child: const Text(AppStrings.orderAgain),
                ),
              ] else ...[
                FilledButton(
                  onPressed: onOrderAgain,
                  child: const Text(AppStrings.orderAgain),
                ),
                if (showFeedback) ...[
                  const SizedBox(height: AppSpacing.xs),
                  OutlinedButton(
                    onPressed: onShareFeedback,
                    child: const Text(AppStrings.feedbackShareCta),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
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
        ? theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          )
        : theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(label, style: labelStyle),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      OrderStatus.cancelled => (AppColors.surfaceMuted, AppColors.error),
      OrderStatus.completed ||
      OrderStatus.delivered =>
        (AppColors.surfaceMuted, AppColors.textSecondary),
      _ => (
          AppColors.primary.withValues(alpha: 0.12),
          AppColors.primary,
        ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        child: Text(
          status.label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}
