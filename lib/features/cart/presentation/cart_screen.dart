import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../application/cart_providers.dart';
import '../domain/cart_line_item.dart';
import 'widgets/cart_line_tile.dart';
import 'widgets/cart_totals_summary.dart';

/// Extremely simple cart: lines, qty controls, notes, totals, checkout CTA.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.cartTitle),
        actions: [
          if (!cart.isEmpty)
            TextButton(
              onPressed: () => _confirmClear(context, ref),
              child: const Text(AppStrings.clearCart),
            ),
        ],
      ),
      body: cart.isEmpty
          ? AppEmptyState(
              icon: Icons.shopping_bag_outlined,
              title: AppStrings.cartEmptyTitle,
              message: AppStrings.cartEmptyBody,
              actionLabel: AppStrings.browseMenu,
              onAction: () => context.go(AppRoutes.home),
            )
          : Column(
              children: [
                Expanded(
                  child: ResponsiveLayout(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.sm,
                      ),
                      children: [
                        for (var i = 0; i < cart.lines.length; i++) ...[
                          if (i > 0) const SizedBox(height: AppSpacing.sm),
                          CartLineTile(
                            line: cart.lines[i],
                            onIncrease: () => ref
                                .read(cartProvider.notifier)
                                .setQuantity(
                                  cart.lines[i].id,
                                  cart.lines[i].quantity + 1,
                                ),
                            onDecrease: () => ref
                                .read(cartProvider.notifier)
                                .setQuantity(
                                  cart.lines[i].id,
                                  cart.lines[i].quantity - 1,
                                ),
                            onRemove: () => ref
                                .read(cartProvider.notifier)
                                .removeLine(cart.lines[i].id),
                            onModify: () => _modifyLine(context, cart.lines[i]),
                            onEditInstructions: () => _editInstructions(
                              context,
                              ref,
                              cart.lines[i],
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        CartTotalsSummary(cart: cart),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Material(
                    elevation: 8,
                    color: AppColors.surface,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.sm,
                        AppSpacing.md,
                        AppSpacing.sm,
                      ),
                      child: ResponsiveLayout(
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => context.push(AppRoutes.checkout),
                            child: const Text(AppStrings.proceedToCheckout),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _modifyLine(BuildContext context, CartLineItem line) {
    context.push(
      AppRoutes.menuItemPath(line.foodItemId),
      extra: line,
    );
  }

  Future<void> _editInstructions(
    BuildContext context,
    WidgetRef ref,
    CartLineItem line,
  ) async {
    final controller = TextEditingController(text: line.specialInstructions);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final bottom = MediaQuery.viewInsetsOf(context).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.md + bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.specialInstructionsTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 3,
                maxLength: 200,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: AppStrings.specialInstructionsHint,
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(AppStrings.saveChanges),
              ),
            ],
          ),
        );
      },
    );

    if (saved == true) {
      ref
          .read(cartProvider.notifier)
          .updateSpecialInstructions(line.id, controller.text);
    }
    controller.dispose();
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.clearCartTitle),
        content: const Text(AppStrings.clearCartBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.clearCart),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(cartProvider.notifier).clear();
    }
  }
}
