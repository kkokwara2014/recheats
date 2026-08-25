import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/presentation/account_inactive_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/foundation/presentation/demo_states_screen.dart';
import '../../features/foundation/presentation/foundation_home_screen.dart';
import '../../features/cart/domain/cart_line_item.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/checkout/presentation/checkout_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/menu/presentation/food_item_detail_screen.dart';
import '../../features/menu/presentation/manage_menu_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/orders/domain/placed_order.dart';
import '../../features/orders/presentation/order_confirmation_screen.dart';
import '../../features/orders/presentation/order_history_screen.dart';
import '../../features/orders/presentation/track_order_screen.dart';
import '../../features/profile/domain/saved_address.dart';
import '../../features/profile/presentation/address_form_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/favorites/presentation/favorites_screen.dart';
import '../../features/profile/presentation/customer_support_screen.dart';
import '../../features/profile/presentation/profile_secondary_screens.dart';
import '../../features/profile/presentation/saved_addresses_screen.dart';
import '../../features/shop/presentation/fulfillment_settings_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import 'app_routes.dart';
import 'main_shell.dart';

/// App-wide [GoRouter] configuration.
abstract final class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  /// Shared production router. Prefer [create] in tests for isolation.
  static final GoRouter config = create();

  static GoRouter create({
    GlobalKey<NavigatorState>? navigatorKey,
    String initialLocation = AppRoutes.splash,
  }) {
    final rootKey = navigatorKey ?? rootNavigatorKey;

    return GoRouter(
      navigatorKey: rootKey,
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: AppRoutes.welcome,
          name: 'welcome',
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.login,
          name: 'login',
          parentNavigatorKey: rootKey,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.register,
          name: 'register',
          parentNavigatorKey: rootKey,
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: AppRoutes.forgotPassword,
          name: 'forgot-password',
          parentNavigatorKey: rootKey,
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: AppRoutes.onboarding,
          name: 'onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: AppRoutes.accountInactive,
          name: 'account-inactive',
          builder: (context, state) => const AccountInactiveScreen(),
        ),

        /// Primary customer tabs: Home · History · Favourites · Profile.
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainShell(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.home,
                  name: 'home',
                  builder: (context, state) => const HomeScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.history,
                  name: 'history',
                  builder: (context, state) => const OrderHistoryScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.favorites,
                  name: 'favorites',
                  builder: (context, state) => const FavoritesScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.profile,
                  name: 'profile',
                  builder: (context, state) => const ProfileScreen(),
                ),
              ],
            ),
          ],
        ),

        // Full-screen flows (cover the bottom nav).
        GoRoute(
          path: AppRoutes.cart,
          name: 'cart',
          parentNavigatorKey: rootKey,
          builder: (context, state) => const CartScreen(),
        ),
        GoRoute(
          path: AppRoutes.checkout,
          name: 'checkout',
          parentNavigatorKey: rootKey,
          builder: (context, state) => const CheckoutScreen(),
        ),
        GoRoute(
          path: AppRoutes.orderConfirmation,
          name: 'order-confirmation',
          parentNavigatorKey: rootKey,
          builder: (context, state) {
            final order = state.extra is PlacedOrder
                ? state.extra as PlacedOrder
                : null;
            if (order == null) {
              return const CheckoutScreen();
            }
            return OrderConfirmationScreen(order: order);
          },
        ),
        GoRoute(
          path: AppRoutes.orderTrack,
          name: 'order-track',
          parentNavigatorKey: rootKey,
          builder: (context, state) {
            final order = state.extra is PlacedOrder
                ? state.extra as PlacedOrder
                : null;
            if (order == null) {
              return const CheckoutScreen();
            }
            return TrackOrderScreen(order: order);
          },
        ),
        GoRoute(
          path: AppRoutes.menuItem,
          name: 'menu-item',
          parentNavigatorKey: rootKey,
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            final editingLine = state.extra is CartLineItem
                ? state.extra as CartLineItem
                : null;
            return FoodItemDetailScreen(
              itemId: id,
              editingLine: editingLine,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.menuManage,
          name: 'menu-manage',
          parentNavigatorKey: rootKey,
          builder: (context, state) => const ManageMenuScreen(),
        ),
        GoRoute(
          path: AppRoutes.fulfillmentSettings,
          name: 'fulfillment-settings',
          parentNavigatorKey: rootKey,
          builder: (context, state) => const FulfillmentSettingsScreen(),
        ),
        GoRoute(
          path: AppRoutes.profileEdit,
          name: 'profile-edit',
          parentNavigatorKey: rootKey,
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: AppRoutes.profileAddresses,
          name: 'profile-addresses',
          parentNavigatorKey: rootKey,
          builder: (context, state) => const SavedAddressesScreen(),
        ),
        GoRoute(
          path: AppRoutes.profileAddressEdit,
          name: 'profile-address-edit',
          parentNavigatorKey: rootKey,
          builder: (context, state) {
            final existing = state.extra is SavedAddress
                ? state.extra as SavedAddress
                : null;
            return AddressFormScreen(existing: existing);
          },
        ),
        // Legacy aliases → primary tabs.
        GoRoute(
          path: AppRoutes.profileOrders,
          name: 'profile-orders',
          redirect: (context, state) => AppRoutes.history,
        ),
        GoRoute(
          path: AppRoutes.profileFavorites,
          name: 'profile-favorites',
          redirect: (context, state) => AppRoutes.favorites,
        ),
        GoRoute(
          path: AppRoutes.profileNotifications,
          name: 'profile-notifications',
          parentNavigatorKey: rootKey,
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: AppRoutes.profileSupport,
          name: 'profile-support',
          parentNavigatorKey: rootKey,
          builder: (context, state) => const CustomerSupportScreen(),
        ),
        GoRoute(
          path: AppRoutes.profileSupportReport,
          name: 'profile-support-report',
          parentNavigatorKey: rootKey,
          builder: (context, state) => const ReportOrderProblemScreen(),
        ),
        GoRoute(
          path: AppRoutes.profileHelp,
          name: 'profile-help',
          parentNavigatorKey: rootKey,
          builder: (context, state) => const CustomerSupportScreen(),
        ),
        GoRoute(
          path: AppRoutes.foundation,
          name: 'foundation',
          parentNavigatorKey: rootKey,
          builder: (context, state) => const FoundationHomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.demoLoading,
          name: 'demo-loading',
          parentNavigatorKey: rootKey,
          builder: (context, state) => const DemoStatesScreen(
            kind: DemoStateKind.loading,
          ),
        ),
        GoRoute(
          path: AppRoutes.demoEmpty,
          name: 'demo-empty',
          parentNavigatorKey: rootKey,
          builder: (context, state) => const DemoStatesScreen(
            kind: DemoStateKind.empty,
          ),
        ),
        GoRoute(
          path: AppRoutes.demoError,
          name: 'demo-error',
          parentNavigatorKey: rootKey,
          builder: (context, state) => const DemoStatesScreen(
            kind: DemoStateKind.error,
          ),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.link_off, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Page not found',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(state.uri.toString()),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go(AppRoutes.welcome),
                  child: const Text('Back to welcome'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
