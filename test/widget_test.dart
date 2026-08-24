import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:recheats/app.dart';
import 'package:recheats/core/config/app_config.dart';
import 'package:recheats/core/constants/app_strings.dart';
import 'package:recheats/core/routing/app_router.dart';
import 'package:recheats/core/routing/app_routes.dart';
import 'package:recheats/features/auth/application/auth_providers.dart';
import 'package:recheats/features/auth/data/auth_repository.dart';
import 'package:recheats/features/auth/domain/auth_validators.dart';
import 'package:recheats/features/auth/domain/register_details.dart';
import 'package:recheats/features/cart/application/cart_providers.dart';
import 'package:recheats/features/cart/domain/cart_line_item.dart';
import 'package:recheats/features/checkout/application/checkout_providers.dart';
import 'package:recheats/features/checkout/domain/delivery_details.dart';
import 'package:recheats/features/checkout/domain/order_timing.dart';
import 'package:recheats/features/menu/application/menu_providers.dart';
import 'package:recheats/features/menu/data/menu_repository.dart';
import 'package:recheats/features/onboarding/application/onboarding_providers.dart';
import 'package:recheats/features/onboarding/data/onboarding_repository.dart';
import 'package:recheats/features/orders/application/order_providers.dart';
import 'package:recheats/features/orders/data/order_repository.dart';
import 'package:recheats/features/orders/domain/order_timeline.dart';
import 'package:recheats/features/orders/domain/place_order_request.dart';
import 'package:recheats/features/orders/domain/placed_order.dart';
import 'package:recheats/features/orders/presentation/track_order_screen.dart';
import 'package:recheats/features/payment/application/payment_providers.dart';
import 'package:recheats/features/payment/data/payment_repository.dart';
import 'package:recheats/features/payment/domain/collect_payment_request.dart';
import 'package:recheats/features/payment/domain/payment_result.dart';
import 'package:recheats/features/profile/application/profile_providers.dart';
import 'package:recheats/features/profile/data/profile_repository.dart';
import 'package:recheats/features/profile/domain/notification_prefs.dart';
import 'package:recheats/features/profile/domain/saved_address.dart';
import 'package:recheats/features/shop/application/shop_providers.dart';
import 'package:recheats/features/shop/data/shop_repository.dart';
import 'package:recheats/features/shop/domain/fulfillment_method.dart';
import 'package:recheats/features/shop/domain/shop_fulfillment_settings.dart';
import 'package:recheats/features/splash/application/startup_gate.dart';
import 'package:recheats/features/splash/application/startup_providers.dart';
import 'package:recheats/features/splash/data/session_repository.dart';
import 'package:recheats/features/splash/domain/session_snapshot.dart';
import 'package:recheats/features/splash/domain/startup_destination.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    PackageInfo.setMockInitialValues(
      appName: 'RechEats',
      packageName: 'org.recheats',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    await AppConfig.ensureInitialized();
  });

  test('startup gate routes by onboarding + session flags', () async {
    Future<void> expectDestination({
      required SessionSnapshot? session,
      required bool onboardingCompleted,
      required StartupDestination expected,
    }) async {
      final gate = StartupGate(
        sessions: FakeSessionRepository(session),
        onboarding: FakeOnboardingRepository(completed: onboardingCompleted),
      );
      expect(
        await gate.resolve(minDisplay: Duration.zero),
        expected,
      );
    }

    await expectDestination(
      session: null,
      onboardingCompleted: false,
      expected: StartupDestination.onboarding,
    );
    await expectDestination(
      session: null,
      onboardingCompleted: true,
      expected: StartupDestination.welcome,
    );
    await expectDestination(
      session: const SessionSnapshot(
        uid: 'u1',
        onboardingCompleted: false,
        isActive: true,
      ),
      onboardingCompleted: true,
      expected: StartupDestination.onboarding,
    );
    await expectDestination(
      session: const SessionSnapshot(
        uid: 'u1',
        onboardingCompleted: true,
        isActive: false,
      ),
      onboardingCompleted: true,
      expected: StartupDestination.accountInactive,
    );
    await expectDestination(
      session: const SessionSnapshot(
        uid: 'u1',
        onboardingCompleted: true,
        isActive: true,
      ),
      onboardingCompleted: true,
      expected: StartupDestination.home,
    );
  }, timeout: const Timeout(Duration(seconds: 10)));

  testWidgets('splash shows RechEats brand then onboarding on first launch', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionRepositoryProvider.overrideWith(
            (ref) => FakeSessionRepository(),
          ),
          onboardingRepositoryProvider.overrideWith(
            (ref) => FakeOnboardingRepository(completed: false),
          ),
        ],
        child: RecheatsApp(
          router: AppRouter.create(
            navigatorKey: GlobalKey<NavigatorState>(),
          ),
        ),
      ),
    );

    expect(find.text(AppStrings.appName), findsWidgets);

    await tester.pump(StartupGate.minDisplayDuration);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.onboardingPage1Title), findsOneWidget);
    expect(find.text(AppStrings.onboardingSkip), findsOneWidget);
    expect(find.text(AppStrings.onboardingNext), findsOneWidget);
  });

  testWidgets('splash goes to welcome when onboarding already done', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionRepositoryProvider.overrideWith(
            (ref) => FakeSessionRepository(),
          ),
          onboardingRepositoryProvider.overrideWith(
            (ref) => FakeOnboardingRepository(completed: true),
          ),
        ],
        child: RecheatsApp(
          router: AppRouter.create(
            navigatorKey: GlobalKey<NavigatorState>(),
          ),
        ),
      ),
    );

    await tester.pump(StartupGate.minDisplayDuration);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.welcomeBody), findsOneWidget);
  });

  testWidgets('onboarding Skip completes and opens welcome', (tester) async {
    final onboarding = FakeOnboardingRepository(completed: false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionRepositoryProvider.overrideWith(
            (ref) => FakeSessionRepository(),
          ),
          onboardingRepositoryProvider.overrideWith((ref) => onboarding),
        ],
        child: RecheatsApp(
          router: AppRouter.create(
            navigatorKey: GlobalKey<NavigatorState>(),
          ),
        ),
      ),
    );

    await tester.pump(StartupGate.minDisplayDuration);
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.onboardingSkip));
    await tester.pumpAndSettle();

    expect(onboarding.completed, isTrue);
    expect(find.text(AppStrings.welcomeBody), findsOneWidget);
  });

  test('auth validators keep registration light but valid', () {
    expect(AuthValidators.firstName(''), isNotNull);
    expect(AuthValidators.email('not-an-email'), isNotNull);
    expect(AuthValidators.email('guest@recheats.app'), isNull);
    expect(AuthValidators.password('123'), isNotNull);
    expect(AuthValidators.password('secret1'), isNull);
    expect(AuthValidators.phoneOptional(''), isNull);
    expect(AuthValidators.phoneOptional('301555'), isNotNull);
    expect(AuthValidators.phoneOptional('3015551234'), isNull);
  });

  test('fake auth repository supports register login reset logout', () async {
    final auth = FakeAuthRepository();

    final registered = await auth.register(
      const RegisterDetails(
        firstName: 'Ada',
        lastName: 'Okafor',
        email: 'ada@example.com',
        password: 'secret1',
        phone: '3015551234',
      ),
      onboardingCompleted: true,
    );
    expect(registered.isSuccess, isTrue);
    expect(auth.signedIn, isTrue);

    final duplicate = await auth.register(
      const RegisterDetails(
        firstName: 'Ada',
        lastName: 'Okafor',
        email: 'ada@example.com',
        password: 'secret1',
      ),
    );
    expect(duplicate.isFailure, isTrue);

    await auth.logout();
    expect(auth.signedIn, isFalse);

    final login = await auth.login(
      email: 'ada@example.com',
      password: 'secret1',
    );
    expect(login.isSuccess, isTrue);

    final reset = await auth.sendPasswordReset('ada@example.com');
    expect(reset.isSuccess, isTrue);
    expect(auth.lastResetEmail, 'ada@example.com');
  });

  test('fake menu repository supports availability without delete', () async {
    final menu = FakeMenuRepository();

    final before = await menu.fetchMenu();
    expect(before.isSuccess, isTrue);
    final jollof = before.valueOrNull!
        .firstWhere((item) => item.id == 'jollof-rice');
    expect(jollof.price, 15);
    expect(jollof.isAvailable, isTrue);
    expect(jollof.variationGroups, isNotEmpty);
    expect(jollof.variationGroups.first.options.length, 4);
    expect(jollof.addOns, isNotEmpty);

    final hidden = await menu.setAvailability(
      id: 'jollof-rice',
      isAvailable: false,
    );
    expect(hidden.isSuccess, isTrue);
    expect(hidden.valueOrNull?.isAvailable, isFalse);

    final catalog = await menu.fetchMenu();
    final stillListed = catalog.valueOrNull!
        .any((item) => item.id == 'jollof-rice');
    expect(stillListed, isTrue);
    expect(
      catalog.valueOrNull!
          .firstWhere((item) => item.id == 'jollof-rice')
          .isAvailable,
      isFalse,
    );

    final restored = await menu.setAvailability(
      id: 'jollof-rice',
      isAvailable: true,
    );
    expect(restored.valueOrNull?.isAvailable, isTrue);
  });

  testWidgets('menu detail shows protein options for jollof', (tester) async {
    final menu = FakeMenuRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          menuRepositoryProvider.overrideWith((ref) => menu),
        ],
        child: RecheatsApp(
          router: AppRouter.create(
            navigatorKey: GlobalKey<NavigatorState>(),
            initialLocation: AppRoutes.menuItemPath('jollof-rice'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Jollof Rice'), findsWidgets);
    expect(find.text(r'$15.00'), findsWidgets);
    expect(find.text('Served with fried plantain.'), findsOneWidget);
    expect(find.text('Protein options'), findsOneWidget);
    expect(find.text(r'Chicken +$5.00'), findsOneWidget);
    expect(find.text(r'Goat meat +$7.00'), findsOneWidget);
    expect(find.text(AppStrings.addOnsTitle), findsOneWidget);
  });

  testWidgets('manage menu can mark a dish unavailable', (tester) async {
    final menu = FakeMenuRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          menuRepositoryProvider.overrideWith((ref) => menu),
        ],
        child: RecheatsApp(
          router: AppRouter.create(
            navigatorKey: GlobalKey<NavigatorState>(),
            initialLocation: AppRoutes.menuManage,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text(AppStrings.manageMenuTitle), findsOneWidget);
    expect(find.text('Jollof Rice'), findsOneWidget);

    final jollofSwitch = find.byType(Switch).first;
    await tester.tap(jollofSwitch);
    await tester.pumpAndSettle();

    final updated = await menu.fetchItem('jollof-rice');
    expect(updated.valueOrNull?.isAvailable, isFalse);
    expect(find.text(AppStrings.unavailableLabel), findsWidgets);
  });

  testWidgets('welcome opens login and signs in to home', (tester) async {
    final auth = FakeAuthRepository();
    final profiles = FakeProfileRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionRepositoryProvider.overrideWith(
            (ref) => FakeSessionRepository(
              const SessionSnapshot(
                uid: 'u1',
                onboardingCompleted: true,
                isActive: true,
              ),
            ),
          ),
          onboardingRepositoryProvider.overrideWith(
            (ref) => FakeOnboardingRepository(completed: true),
          ),
          authRepositoryProvider.overrideWith((ref) => auth),
          profileRepositoryProvider.overrideWith((ref) => profiles),
        ],
        child: RecheatsApp(
          router: AppRouter.create(
            navigatorKey: GlobalKey<NavigatorState>(),
            initialLocation: AppRoutes.welcome,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text(AppStrings.signIn), findsOneWidget);

    await tester.tap(find.text(AppStrings.signIn));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.loginTitle), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'guest@recheats.app',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secret1');
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.signIn));
    await tester.pumpAndSettle();

    expect(auth.signedIn, isTrue);
    expect(find.text(AppStrings.homeGreeting('Rechael')), findsOneWidget);
    expect(find.text(AppStrings.homeTitle), findsOneWidget);
    expect(find.text(AppStrings.browseMenu), findsOneWidget);
    expect(find.text(AppStrings.todaysSpecials), findsOneWidget);
    expect(find.byTooltip(AppStrings.openProfile), findsOneWidget);

    final homeScroll = find.byType(CustomScrollView);
    await tester.scrollUntilVisible(
      find.text(AppStrings.popularMeals),
      200,
      scrollable: find.descendant(
        of: homeScroll,
        matching: find.byType(Scrollable),
      ).first,
    );
    expect(find.text(AppStrings.popularMeals), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text(AppStrings.orderNow),
      200,
      scrollable: find.descendant(
        of: homeScroll,
        matching: find.byType(Scrollable),
      ).first,
    );
    expect(find.text(AppStrings.orderNow), findsOneWidget);
  });

  test('fake profile repository manages details addresses and prefs', () async {
    final profiles = FakeProfileRepository();

    final updated = await profiles.updateDetails(
      firstName: 'Ada',
      lastName: 'Okafor',
      email: 'ada@example.com',
      phone: '3015559999',
    );
    expect(updated.isSuccess, isTrue);
    expect(updated.valueOrNull?.displayName, 'Ada Okafor');

    final saved = await profiles.saveAddress(
      const SavedAddress(
        id: 'a1',
        label: 'Home',
        line1: '1 Main St',
        line2: 'Apt 2',
        city: 'Rockville',
        state: 'MD',
        zip: '20850',
        instructions: 'Leave at door',
        isDefault: true,
      ),
    );
    expect(saved.isSuccess, isTrue);
    expect(saved.valueOrNull?.addresses, hasLength(1));
    expect(saved.valueOrNull?.addresses.first.instructions, 'Leave at door');
    expect(saved.valueOrNull?.addresses.first.addressLabel.name, 'home');

    final prefs = await profiles.updateNotifications(
      const NotificationPrefs(orderUpdates: true, promotions: true),
    );
    expect(prefs.valueOrNull?.notifications.promotions, isTrue);

    final cleared = await profiles.clearPhoto();
    expect(cleared.valueOrNull?.photoUrl, isNull);
  });

  test('fake shop repository saves fulfillment settings', () async {
    final shop = FakeShopRepository();

    final saved = await shop.saveFulfillmentSettings(
      const ShopFulfillmentSettings(
        pickupEnabled: true,
        deliveryEnabled: false,
        pickupLocation: '123 Kitchen Ave, Rockville',
        deliveryFee: 0,
      ),
    );
    expect(saved.isSuccess, isTrue);
    expect(saved.valueOrNull?.offersDelivery, isFalse);
    expect(saved.valueOrNull?.pickupLocation, '123 Kitchen Ave, Rockville');

    final bothOff = await shop.saveFulfillmentSettings(
      const ShopFulfillmentSettings(
        pickupEnabled: false,
        deliveryEnabled: false,
      ),
    );
    expect(bothOff.isFailure, isTrue);
  });

  test('fake order repository records pickup and delivery orders', () async {
    final orders = FakeOrderRepository();
    const line = CartLineItem(
      id: 'c1',
      foodItemId: 'jollof-rice',
      name: 'Jollof Rice',
      unitPrice: 15,
      quantity: 1,
    );

    final pickup = await orders.placeOrder(
      const PlaceOrderRequest(
        lines: [line],
        method: FulfillmentMethod.pickup,
        pickupLocation: 'Rockville, Maryland',
        subtotal: 15,
        deliveryFee: 0,
        total: 15,
      ),
    );
    expect(pickup.isSuccess, isTrue);
    expect(pickup.valueOrNull?.isPickup, isTrue);
    expect(pickup.valueOrNull?.deliveryFee, 0);
    expect(pickup.valueOrNull?.timing.isAsap, isTrue);
    expect(pickup.valueOrNull?.status, OrderStatus.received);

    final scheduledAt = DateTime(2026, 8, 28, 18, 30);
    final delivery = await orders.placeOrder(
      PlaceOrderRequest(
        lines: const [line],
        method: FulfillmentMethod.delivery,
        delivery: const DeliveryDetails(
          streetAddress: '1 Main St',
          apartmentUnit: '2B',
          city: 'Rockville',
          state: 'MD',
          zip: '20850',
          instructions: 'Ring bell',
        ),
        timing: OrderTiming(
          mode: OrderTimingMode.scheduled,
          scheduledAt: scheduledAt,
        ),
        subtotal: 15,
        deliveryFee: 5,
        total: 20,
      ),
    );
    expect(delivery.isSuccess, isTrue);
    expect(delivery.valueOrNull?.isDelivery, isTrue);
    expect(delivery.valueOrNull?.delivery?.apartmentUnit, '2B');
    expect(delivery.valueOrNull?.timing.isScheduled, isTrue);
    expect(delivery.valueOrNull?.timing.displayLabel, 'Friday, 6:30 PM');
    expect(orders.orders, hasLength(2));
  });

  test('order timeline uses pickup vs delivery status steps', () {
    expect(
      OrderTimeline.stepsFor(FulfillmentMethod.pickup).map((s) => s.label),
      [
        'Order Received',
        'Confirmed',
        'Preparing',
        'Ready',
        'Completed',
      ],
    );
    expect(
      OrderTimeline.stepsFor(FulfillmentMethod.delivery).map((s) => s.label),
      [
        'Order Received',
        'Confirmed',
        'Preparing',
        'Out for Delivery',
        'Delivered',
      ],
    );
    expect(parseOrderStatus('recorded'), OrderStatus.confirmed);
    expect(parseOrderStatus('outForDelivery'), OrderStatus.outForDelivery);
    expect(
      OrderTimeline.activeIndex(
        OrderStatus.preparing,
        FulfillmentMethod.pickup,
      ),
      2,
    );
  });

  test('fake order repository advances status for live tracking', () async {
    final orders = FakeOrderRepository();
    final placed = await orders.placeOrder(
      const PlaceOrderRequest(
        lines: [
          CartLineItem(
            id: 'c1',
            foodItemId: 'jollof-rice',
            name: 'Jollof Rice',
            unitPrice: 15,
            quantity: 1,
          ),
        ],
        method: FulfillmentMethod.delivery,
        delivery: DeliveryDetails(
          streetAddress: '1 Main St',
          city: 'Rockville',
          state: 'MD',
          zip: '20850',
        ),
        subtotal: 15,
        deliveryFee: 5,
        total: 20,
      ),
    );
    final orderId = placed.valueOrNull!.id;

    final events = <OrderStatus>[];
    final sub = orders.watchOrder(orderId).listen((result) {
      final status = result.valueOrNull?.status;
      if (status != null) events.add(status);
    });

    await Future<void>.delayed(Duration.zero);
    await orders.updateOrderStatus(
      orderId: orderId,
      status: OrderStatus.confirmed,
    );
    await orders.updateOrderStatus(
      orderId: orderId,
      status: OrderStatus.outForDelivery,
    );
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(events, contains(OrderStatus.received));
    expect(events, contains(OrderStatus.confirmed));
    expect(events, contains(OrderStatus.outForDelivery));
  });

  testWidgets('track order screen shows pickup timeline', (tester) async {
    final orders = FakeOrderRepository();
    final placed = await orders.placeOrder(
      const PlaceOrderRequest(
        lines: [
          CartLineItem(
            id: 'c1',
            foodItemId: 'jollof-rice',
            name: 'Jollof Rice',
            unitPrice: 15,
            quantity: 1,
          ),
        ],
        method: FulfillmentMethod.pickup,
        pickupLocation: 'Rockville, Maryland',
        subtotal: 15,
        deliveryFee: 0,
        total: 15,
      ),
    );
    final order = placed.valueOrNull!;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          orderRepositoryProvider.overrideWith((ref) => orders),
        ],
        child: MaterialApp(
          home: TrackOrderScreen(order: order),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Order Received'), findsWidgets);
    expect(find.text('Confirmed'), findsOneWidget);
    expect(find.text('Preparing'), findsOneWidget);
    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Out for Delivery'), findsNothing);
    expect(find.text(AppStrings.trackOrderSubtitlePickup), findsOneWidget);
  });

  testWidgets('track order screen shows delivery timeline', (tester) async {
    final orders = FakeOrderRepository();
    final placed = await orders.placeOrder(
      const PlaceOrderRequest(
        lines: [
          CartLineItem(
            id: 'c1',
            foodItemId: 'jollof-rice',
            name: 'Jollof Rice',
            unitPrice: 15,
            quantity: 1,
          ),
        ],
        method: FulfillmentMethod.delivery,
        delivery: DeliveryDetails(
          streetAddress: '1 Main St',
          city: 'Rockville',
          state: 'MD',
          zip: '20850',
        ),
        subtotal: 15,
        deliveryFee: 5,
        total: 20,
      ),
    );
    final order = placed.valueOrNull!;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          orderRepositoryProvider.overrideWith((ref) => orders),
        ],
        child: MaterialApp(
          home: TrackOrderScreen(order: order),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Out for Delivery'), findsOneWidget);
    expect(find.text('Delivered'), findsOneWidget);
    expect(find.text('Ready'), findsNothing);
    expect(find.text('Completed'), findsNothing);
    expect(find.text(AppStrings.trackOrderSubtitleDelivery), findsOneWidget);
  });

  testWidgets('fulfillment settings can disable delivery', (tester) async {
    final shop = FakeShopRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shopRepositoryProvider.overrideWith((ref) => shop),
        ],
        child: RecheatsApp(
          router: AppRouter.create(
            navigatorKey: GlobalKey<NavigatorState>(),
            initialLocation: AppRoutes.fulfillmentSettings,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text(AppStrings.fulfillmentSettingsTitle), findsOneWidget);
    expect(find.text(AppStrings.fulfillmentOfferDelivery), findsOneWidget);

    final switches = find.byType(Switch);
    await tester.tap(switches.at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.saveChanges));
    await tester.pumpAndSettle();

    final loaded = await shop.fetchFulfillmentSettings();
    expect(loaded.valueOrNull?.offersDelivery, isFalse);
    expect(loaded.valueOrNull?.offersPickup, isTrue);
  });

  testWidgets('checkout pickup places order without delivery fee', (tester) async {
    final shop = FakeShopRepository();
    final orders = FakeOrderRepository();
    final payments = FakePaymentRepository();
    final container = ProviderContainer(
      overrides: [
        shopRepositoryProvider.overrideWith((ref) => shop),
        orderRepositoryProvider.overrideWith((ref) => orders),
        paymentRepositoryProvider.overrideWith((ref) => payments),
        profileRepositoryProvider.overrideWith((ref) => FakeProfileRepository()),
      ],
    );
    addTearDown(container.dispose);

    container.read(cartProvider.notifier).addItem(
          foodItemId: 'jollof-rice',
          name: 'Jollof Rice',
          unitPrice: 15,
          quantity: 1,
        );
    container.read(checkoutProvider.notifier).selectMethod(FulfillmentMethod.pickup);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: RecheatsApp(
          router: AppRouter.create(
            navigatorKey: GlobalKey<NavigatorState>(),
            initialLocation: AppRoutes.checkout,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text(AppStrings.checkoutYourOrder), findsOneWidget);
    expect(find.text('Jollof Rice'), findsOneWidget);
    expect(find.text(AppStrings.fulfillmentPickup), findsOneWidget);
    expect(find.text(AppStrings.orderTimingAsap), findsOneWidget);
    expect(
      find.textContaining('ready for pickup at'),
      findsOneWidget,
    );

    final checkoutScroll = find.descendant(
      of: find.byType(ListView),
      matching: find.byType(Scrollable),
    ).first;
    await tester.scrollUntilVisible(
      find.text(AppStrings.paymentTitle),
      120,
      scrollable: checkoutScroll,
    );
    expect(find.text(AppStrings.paymentTitle), findsOneWidget);
    expect(find.text(AppStrings.paymentSecureHeadline), findsOneWidget);
    expect(find.text(AppStrings.paymentMethodCard), findsOneWidget);

    await tester.tap(find.text(AppStrings.payAndPlaceOrder));
    await tester.pumpAndSettle();

    expect(payments.requests, hasLength(1));
    expect(payments.requests.first.amountCents, 1500);
    expect(payments.requests.first.currency, 'usd');
    expect(orders.orders, hasLength(1));
    expect(orders.orders.first.isPickup, isTrue);
    expect(orders.orders.first.timing.isAsap, isTrue);
    expect(orders.orders.first.total, 15);
    expect(orders.orders.first.payment?.isPaid, isTrue);
    expect(orders.orders.first.payment?.paymentIntentId, isNotEmpty);
    expect(orders.orders.first.displayCode, 'RE1001');
    expect(find.text(AppStrings.orderConfirmedHeadline), findsOneWidget);
    expect(find.text(AppStrings.orderConfirmedNumber('RE1001')), findsOneWidget);
    expect(find.text(AppStrings.orderConfirmedThanks), findsOneWidget);
    expect(find.text(AppStrings.orderConfirmedItems), findsOneWidget);
    expect(find.text(AppStrings.trackOrder), findsOneWidget);
    expect(find.text(AppStrings.orderTimingAsap), findsWidgets);
    expect(container.read(cartProvider).isEmpty, isTrue);
  });

  test('fake payment repository collects usd cents without card data', () async {
    final payments = FakePaymentRepository();
    final result = await payments.collectPayment(
      const CollectPaymentRequest(amountCents: 2099, currency: 'usd'),
    );
    expect(result, isA<PaymentSucceeded>());
    final payment = (result as PaymentSucceeded).payment;
    expect(payment.provider, 'stripe');
    expect(payment.amountCents, 2099);
    expect(payment.isPaid, isTrue);
    expect(payment.toMap().containsKey('cardNumber'), isFalse);
  });

  testWidgets('profile hub shows account menu and logs out', (tester) async {
    final auth = FakeAuthRepository()..signedIn = true;
    final profiles = FakeProfileRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionRepositoryProvider.overrideWith(
            (ref) => FakeSessionRepository(
              const SessionSnapshot(
                uid: 'u1',
                onboardingCompleted: true,
                isActive: true,
              ),
            ),
          ),
          onboardingRepositoryProvider.overrideWith(
            (ref) => FakeOnboardingRepository(completed: true),
          ),
          authRepositoryProvider.overrideWith((ref) => auth),
          profileRepositoryProvider.overrideWith((ref) => profiles),
        ],
        child: RecheatsApp(
          router: AppRouter.create(
            navigatorKey: GlobalKey<NavigatorState>(),
            initialLocation: AppRoutes.profile,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Rechael Guest'), findsOneWidget);
    expect(find.text(AppStrings.editProfile), findsOneWidget);
    expect(find.text(AppStrings.savedAddresses), findsOneWidget);
    expect(find.text(AppStrings.manageMenu), findsOneWidget);
    expect(find.text(AppStrings.fulfillmentSettings), findsOneWidget);

    final listScroll = find.descendant(
      of: find.byType(ListView),
      matching: find.byType(Scrollable),
    ).first;
    await tester.scrollUntilVisible(
      find.text(AppStrings.help),
      120,
      scrollable: listScroll,
    );
    expect(find.text(AppStrings.orderHistory), findsOneWidget);
    expect(find.text(AppStrings.favorites), findsOneWidget);
    expect(find.text(AppStrings.notifications), findsOneWidget);
    expect(find.text(AppStrings.help), findsOneWidget);

    final logout = find.text(AppStrings.logout);
    await tester.scrollUntilVisible(logout, 120, scrollable: listScroll);
    await tester.ensureVisible(logout);
    await tester.pumpAndSettle();
    await tester.tap(logout);
    await tester.pumpAndSettle();

    expect(auth.signedIn, isFalse);
    expect(find.text(AppStrings.continueAsGuest), findsOneWidget);
  });
}
