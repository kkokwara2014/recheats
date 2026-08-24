import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../payment/application/payment_providers.dart';
import '../../../payment/domain/payment_method_kind.dart';

/// Checkout payment summary — Stripe (card + wallets); no card fields in-app.
class CheckoutPaymentSection extends ConsumerWidget {
  const CheckoutPaymentSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final methods = ref.watch(supportedPaymentMethodsProvider);
    final live = ref.watch(paymentRepositoryProvider).isLiveStripeConfigured;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.paymentTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        DecoratedBox(
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
                    const Icon(
                      Icons.lock_outline,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.paymentSecureHeadline,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            AppStrings.paymentSecureBody,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final method in methods)
                      _PaymentMethodChip(kind: method),
                  ],
                ),
                if (!live) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Dev mode: Stripe keys not set — checkout uses a local '
                    'mock charge (still no card data in Firebase).',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodChip extends StatelessWidget {
  const _PaymentMethodChip({required this.kind});

  final PaymentMethodKind kind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, label) = switch (kind) {
      PaymentMethodKind.card => (
          Icons.credit_card,
          AppStrings.paymentMethodCard,
        ),
      PaymentMethodKind.applePay => (
          Icons.apple,
          AppStrings.paymentMethodApplePay,
        ),
      PaymentMethodKind.googlePay => (
          Icons.account_balance_wallet_outlined,
          AppStrings.paymentMethodGooglePay,
        ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.primaryDark),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
