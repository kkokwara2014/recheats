import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/error_handler.dart';
import '../../orders/domain/placed_order.dart';
import '../application/feedback_providers.dart';
import '../domain/order_feedback.dart';

/// Opens the post-order rating sheet. Returns `true` if feedback was sent.
Future<bool> showOrderFeedbackSheet({
  required BuildContext context,
  required WidgetRef ref,
  required PlacedOrder order,
  bool allowSkip = true,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: _OrderFeedbackSheet(
          order: order,
          allowSkip: allowSkip,
        ),
      );
    },
  );
  return result == true;
}

/// Auto-prompts once when an order reaches completed/delivered.
Future<void> maybePromptOrderFeedback({
  required BuildContext context,
  required WidgetRef ref,
  required PlacedOrder order,
}) async {
  if (!OrderFeedback.isEligible(order.status)) return;

  final repo = ref.read(feedbackRepositoryProvider);
  if (await repo.hasSubmitted(order.id)) return;
  if (await repo.hasPromptDismissed(order.id)) return;
  if (!context.mounted) return;

  final submitted = await showOrderFeedbackSheet(
    context: context,
    ref: ref,
    order: order,
  );

  if (!submitted) {
    await repo.dismissPrompt(order.id);
  }
}

class _OrderFeedbackSheet extends ConsumerStatefulWidget {
  const _OrderFeedbackSheet({
    required this.order,
    required this.allowSkip,
  });

  final PlacedOrder order;
  final bool allowSkip;

  @override
  ConsumerState<_OrderFeedbackSheet> createState() =>
      _OrderFeedbackSheetState();
}

class _OrderFeedbackSheetState extends ConsumerState<_OrderFeedbackSheet> {
  final _commentController = TextEditingController();
  int _rating = 0;
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xs,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.feedbackTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              AppStrings.orderConfirmedNumber(widget.order.displayCode),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var star = 1; star <= 5; star++)
                  IconButton(
                    onPressed: _submitting
                        ? null
                        : () => setState(() => _rating = star),
                    iconSize: 36,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxs,
                    ),
                    icon: Icon(
                      star <= _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: star <= _rating
                          ? AppColors.accent
                          : AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _commentController,
              enabled: !_submitting,
              maxLines: 4,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: AppStrings.feedbackCommentLabel,
                hintText: AppStrings.feedbackCommentHint,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: _submitting || _rating < 1 ? null : _submit,
              child: Text(
                _submitting
                    ? AppStrings.feedbackSending
                    : AppStrings.feedbackSubmit,
              ),
            ),
            if (widget.allowSkip) ...[
              const SizedBox(height: AppSpacing.xs),
              TextButton(
                onPressed:
                    _submitting ? null : () => Navigator.pop(context, false),
                child: const Text(AppStrings.feedbackSkip),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);

    final feedback = OrderFeedback(
      orderId: widget.order.id,
      displayCode: widget.order.displayCode,
      userId: widget.order.userId,
      rating: _rating,
      comment: _commentController.text.trim(),
      createdAt: DateTime.now(),
    );

    final result =
        await ref.read(feedbackRepositoryProvider).submit(feedback);

    if (!mounted) return;

    result.when(
      success: (_) {
        invalidateOrderFeedback(ref, widget.order.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.feedbackThanks)),
        );
        Navigator.pop(context, true);
      },
      failure: (error, _) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.userMessage(error))),
        );
      },
    );
  }
}
