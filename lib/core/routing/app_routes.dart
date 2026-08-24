/// Central route path constants.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String onboarding = '/onboarding';
  static const String accountInactive = '/account-inactive';
  static const String home = '/home';

  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String orderConfirmation = '/order/confirmation';
  static const String orderTrack = '/order/track';

  static const String menuItem = '/menu/item/:id';
  static const String menuManage = '/menu/manage';
  static const String fulfillmentSettings = '/shop/fulfillment';

  static String menuItemPath(String id) => '/menu/item/$id';

  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String profileAddresses = '/profile/addresses';
  static const String profileAddressEdit = '/profile/addresses/edit';
  static const String profileOrders = '/profile/orders';
  static const String profileFavorites = '/profile/favorites';
  static const String profileNotifications = '/profile/notifications';
  static const String profileHelp = '/profile/help';
  static const String profileSupport = '/profile/support';
  static const String profileSupportReport = '/profile/support/report';

  /// Module 1 foundation demos (kept for local verification).
  static const String foundation = '/foundation';
  static const String demoLoading = '/demo/loading';
  static const String demoEmpty = '/demo/empty';
  static const String demoError = '/demo/error';
}
