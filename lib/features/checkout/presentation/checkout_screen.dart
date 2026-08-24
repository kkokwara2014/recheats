import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../cart/application/cart_providers.dart';
import '../../cart/domain/cart_state.dart';
import '../../orders/application/order_providers.dart';
import '../../orders/domain/place_order_request.dart';
import '../../orders/domain/placed_order.dart';
import '../../profile/application/profile_providers.dart';
import '../../profile/domain/saved_address.dart';
import '../../shop/application/shop_providers.dart';
import '../../shop/domain/fulfillment_method.dart';
import '../../shop/domain/shop_fulfillment_settings.dart';
import '../application/checkout_providers.dart';
import '../domain/checkout_state.dart';
import 'widgets/checkout_order_summary.dart';
import 'widgets/checkout_payment_section.dart';
import 'widgets/checkout_totals_summary.dart';
import 'widgets/delivery_details_form.dart';
import 'widgets/fulfillment_method_selector.dart';
import 'widgets/order_timing_selector.dart';
import 'widgets/pickup_info_card.dart';

/// One-page checkout: order lines, fulfillment, timing, payment, place order.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _placing = false;

  Future<void> _placeOrder() async {
    if (_placing) return;

    final cart = ref.read(cartProvider);
    final checkout = ref.read(checkoutProvider);
    final settings = ref.read(shopFulfillmentSettingsProvider).asData?.value;
    if (cart.isEmpty || settings == null) return;

    final validation = checkout.validationMessage(settings);
    if (validation != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validation)),
      );
      return;
    }

    final method = checkout.method!;
    setState(() => _placing = true);

    final profile = ref.read(customerProfileProvider).asData?.value;
    final request = PlaceOrderRequest(
      userId: profile?.uid,
      lines: cart.lines,
      method: method,
      pickupLocation:
          method == FulfillmentMethod.pickup ? settings.pickupLocation : null,
      delivery:
          method == FulfillmentMethod.delivery ? checkout.delivery : null,
      timing: checkout.timing,
      subtotal: cart.subtotal,
      deliveryFee: checkout.deliveryFee(settings),
      total: checkout.total(cart, settings),
    );

    final result = await ref.read(orderRepositoryProvider).placeOrder(request);
    if (!mounted) return;

    result.when(
      success: (order) {
        ref.read(cartProvider.notifier).clear();
        ref.read(checkoutProvider.notifier).reset();
        context.go(AppRoutes.orderConfirmation, extra: order);
      },
      failure: (error, _) {
        setState(() => _placing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.userMessage(error))),
        );
      },
    );
  }

  Future<void> _pickScheduleSlot() async {
    final current = ref.read(checkoutProvider).timing.scheduledAt;
    final now = DateTime.now();
    final initialDate = current != null && current.isAfter(now)
        ? current
        : now.add(const Duration(hours: 1));

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 30)),
    );
    if (!mounted || date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (!mounted || time == null) return;

    final scheduled = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    ref.read(checkoutProvider.notifier).setScheduledAt(scheduled);
  }

  void _onSelectScheduled() {
    final notifier = ref.read(checkoutProvider.notifier);
    final timing = ref.read(checkoutProvider).timing;
    notifier.selectScheduled(at: timing.scheduledAt);
    if (timing.scheduledAt == null) {
      _pickScheduleSlot();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<ShopFulfillmentSettings>>(
      shopFulfillmentSettingsProvider,
      (previous, next) {
        next.whenData((settings) {
          ref.read(checkoutProvider.notifier).syncWithSettings(settings);
        });
      },
    );
    ref.listen(customerProfileProvider, (previous, next) {
      next.whenData((profile) {
        ref
            .read(checkoutProvider.notifier)
            .seedAddressIfNeeded(profile?.addresses ?? const []);
      });
    });

    final cart = ref.watch(cartProvider);
    final checkout = ref.watch(checkoutProvider);
    final settingsAsync = ref.watch(shopFulfillmentSettingsProvider);
    final profileAsync = ref.watch(customerProfileProvider);

    // Seed once settings / profile are already available on first frame.
    final settings = settingsAsync.asData?.value;
    if (settings != null) {
      final notifier = ref.read(checkoutProvider.notifier);
      final current = checkout.method;
      if (current == null || !settings.supports(current)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          notifier.syncWithSettings(settings);
        });
      }
      final addresses = profileAsync.asData?.value?.addresses;
      if (addresses != null &&
          addresses.isNotEmpty &&
          !checkout.delivery.hasStreet) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          notifier.seedAddressIfNeeded(addresses);
        });
      }
    }

    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.checkoutTitle)),
        body: AppEmptyState(
          icon: Icons.shopping_bag_outlined,
          title: AppStrings.cartEmptyTitle,
          message: AppStrings.cartEmptyBody,
          actionLabel: AppStrings.browseMenu,
          onAction: () => context.go(AppRoutes.home),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.checkoutTitle)),
      body: settingsAsync.when(
        loading: () => const AppLoading(),
        error: (error, _) => AppErrorView(
          error: error,
          onRetry: () => invalidateShopFulfillmentSettings(ref),
        ),
        data: (settings) => _CheckoutBody(
          settings: settings,
          checkout: checkout,
          cart: cart,
          savedAddresses: profileAsync.asData?.value?.addresses ?? const [],
          placing: _placing,
          onPlaceOrder: _placeOrder,
          onSelectMethod: (method) =>
              ref.read(checkoutProvider.notifier).selectMethod(method),
          onSelectAsap: () => ref.read(checkoutProvider.notifier).selectAsap(),
          onSelectScheduled: _onSelectScheduled,
          onPickSlot: _pickScheduleSlot,
        ),
      ),
    );
  }
}

class _CheckoutBody extends StatelessWidget {
  const _CheckoutBody({
    required this.settings,
    required this.checkout,
    required this.cart,
    required this.savedAddresses,
    required this.placing,
    required this.onPlaceOrder,
    required this.onSelectMethod,
    required this.onSelectAsap,
    required this.onSelectScheduled,
    required this.onPickSlot,
  });

  final ShopFulfillmentSettings settings;
  final CheckoutState checkout;
  final CartState cart;
  final List<SavedAddress> savedAddresses;
  final bool placing;
  final VoidCallback onPlaceOrder;
  final ValueChanged<FulfillmentMethod> onSelectMethod;
  final VoidCallback onSelectAsap;
  final VoidCallback onSelectScheduled;
  final VoidCallback onPickSlot;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ResponsiveLayout(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                CheckoutOrderSummary(lines: cart.lines),
                const SizedBox(height: AppSpacing.lg),
                FulfillmentMethodSelector(
                  settings: settings,
                  selected: checkout.method,
                  onChanged: onSelectMethod,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (checkout.isPickup)
                  PickupInfoCard(location: settings.pickupLocation),
                if (checkout.isDelivery)
                  DeliveryDetailsForm(
                    details: checkout.delivery,
                    savedAddresses: savedAddresses,
                  ),
                if (checkout.isPickup || checkout.isDelivery)
                  const SizedBox(height: AppSpacing.lg),
                OrderTimingSelector(
                  timing: checkout.timing,
                  onSelectAsap: onSelectAsap,
                  onSelectScheduled: onSelectScheduled,
                  onPickSlot: onPickSlot,
                ),
                const SizedBox(height: AppSpacing.lg),
                const CheckoutPaymentSection(),
                const SizedBox(height: AppSpacing.lg),
                CheckoutTotalsSummary(
                  cart: cart,
                  checkout: checkout,
                  settings: settings,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  AppStrings.checkoutRecordHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
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
                    onPressed:
                        settings.hasAnyMethod && !placing ? onPlaceOrder : null,
                    child: placing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textOnPrimary,
                            ),
                          )
                        : const Text(AppStrings.placeOrder),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Shown after an order is recorded with pickup or delivery details.
class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key, required this.order});

  final PlacedOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = order.isPickup
        ? AppStrings.pickupReadyMessage(
            order.pickupLocation ?? AppStrings.locationHint,
          )
        : AppStrings.deliveryOrderRecordedMessage(
            order.delivery?.formattedAddress ?? '',
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.orderConfirmedTitle),
        automaticallyImplyLeading: false,
      ),
      body: ResponsiveLayout(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 64,
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
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppStrings.orderConfirmedTiming(order.timing.displayLabel),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (order.isDelivery &&
                  (order.delivery?.instructions.trim().isNotEmpty ??
                      false)) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  '${AppStrings.deliveryInstructions}: ${order.delivery!.instructions.trim()}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text(
                AppStrings.orderConfirmedTotal(
                  '\$${order.total.toStringAsFixed(2)}',
                ),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text(AppStrings.backToMenu),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
