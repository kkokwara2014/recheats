/// User-facing copy used across the foundation and later modules.
abstract final class AppStrings {
  static const String appName = 'RechEats';
  static const String tagline = 'Authentic Nigerian Food, Made with Love.';
  static const String locationHint = 'Rockville, Maryland';

  static const String loadingDefault = 'Loading…';
  static const String retry = 'Try again';
  static const String goBack = 'Go back';
  static const String somethingWentWrong = 'Something went wrong';
  static const String somethingWentWrongBody =
      'We hit an unexpected issue. Please try again in a moment.';
  static const String offlineTitle = 'You\'re offline';
  static const String offlineBody =
      'Check your connection and try again when you\'re back online.';
  static const String emptyDefaultTitle = 'Nothing here yet';
  static const String emptyDefaultBody =
      'When there\'s something to show, it will appear here.';

  static const String foundationTitle = 'App foundation ready';
  static const String foundationBody =
      'Theme, navigation, environments, and Firebase wiring are in place. '
      'Next up: menu browsing and ordering.';

  static const String welcomeBody =
      'Sign in to order Rechael\'s Nigerian menu quickly — '
      'or browse as a guest.';
  static const String continueAsGuest = 'Continue as guest';
  static const String openFoundation = 'Open foundation demos';
  static const String continueLabel = 'Continue';

  static const String signIn = 'Sign in';
  static const String createAccount = 'Create account';
  static const String logout = 'Log out';
  static const String forgotPassword = 'Forgot password?';
  static const String sendResetLink = 'Send reset link';
  static const String backToSignIn = 'Back to sign in';
  static const String needAccount = 'Need an account? Create one';
  static const String haveAccount = 'Already have an account? Sign in';

  static const String loginTitle = 'Welcome back';
  static const String loginSubtitle = 'Sign in with your email to keep ordering fast.';
  static const String registerTitle = 'Create your account';
  static const String registerSubtitle =
      'A few details so checkout stays quick next time.';
  static const String forgotPasswordTitle = 'Reset password';
  static const String forgotPasswordSubtitle =
      'Enter your email and we\'ll send a reset link.';
  static const String forgotPasswordSentBody =
      'If an account exists for that email, a reset link is on the way. '
      'Check your inbox.';

  static const String firstNameLabel = 'First name';
  static const String lastNameLabel = 'Last name';
  static const String emailLabel = 'Email';
  static const String phoneOptionalLabel = 'Phone number (optional)';
  static const String phoneOptionalHelper =
      'Optional — helps with order updates. No SMS code required.';
  static const String passwordLabel = 'Password';
  static const String confirmPasswordLabel = 'Confirm password';

  static const String onboardingSkip = 'Skip';
  static const String onboardingNext = 'Next';
  static const String onboardingGetStarted = 'Get Started';

  static const String onboardingPage1Title = 'Authentic Nigerian Delicacies';
  static const String onboardingPage1Body =
      'Discover delicious Nigerian meals prepared by Rechael.';

  static const String onboardingPage2Title = 'Order With Ease';
  static const String onboardingPage2Body =
      'Browse the menu and place your order in just a few taps.';

  static const String onboardingPage3Title = 'Freshly Prepared for You';
  static const String onboardingPage3Body =
      'Choose pickup or delivery and receive your order.';

  static const String accountInactiveTitle = 'Account inactive';
  static const String accountInactiveBody =
      'This account is currently inactive. Contact RechEats if you need help '
      'getting back in.';
  static const String backToWelcome = 'Back to welcome';

  static const String homeTitle = 'What are you hungry for today?';
  static const String homeGreetingGuest = 'Hello there';
  static String homeGreeting(String firstName) => 'Hello, $firstName';
  static const String homeHeroTitle = 'Authentic Nigerian Food';
  static const String homeHeroSubtitle = 'Made Fresh for You';
  static const String browseMenu = 'Browse Menu';
  static const String categoriesTitle = 'Categories';
  static const String categoryAll = 'All';
  static const String todaysSpecials = 'Today\'s Specials';
  static const String popularMeals = 'Popular Meals';
  static const String orderNow = 'Order Now';
  static const String addToOrder = 'Add';
  static const String addToCart = 'Add to Cart';
  static const String addedToOrder = 'Added to your order';
  static const String addedToCart = 'Added to cart';
  static String addedToCartNamed(String name) => '$name — added to cart';
  static String cartUpdatedNamed(String name) => '$name — cart updated';
  static const String orderNowHint = 'Pick a meal above to get started.';
  static const String openProfile = 'Profile';
  static const String openCart = 'Cart';

  static const String cartTitle = 'Cart';
  static const String cartEmptyTitle = 'Your cart is empty';
  static const String cartEmptyBody =
      'Add a few dishes from the menu, then come back to check out.';
  static const String clearCart = 'Clear';
  static const String clearCartTitle = 'Clear cart?';
  static const String clearCartBody =
      'Remove all items from your cart? This cannot be undone.';
  static const String increaseQuantity = 'Increase quantity';
  static const String decreaseQuantity = 'Decrease quantity';
  static const String removeItem = 'Remove item';
  static const String modifyItem = 'Modify';
  static const String addInstructions = 'Add note';
  static const String editInstructions = 'Edit note';
  static const String subtotal = 'Subtotal';
  static const String deliveryFee = 'Delivery';
  static const String orderTotal = 'Total';
  static const String proceedToCheckout = 'Proceed to Checkout';
  static const String updateCartItem = 'Update item';
  static const String checkoutTitle = 'Checkout';
  static const String checkoutComingSoonTitle = 'Checkout is next';
  static const String checkoutComingSoonBody =
      'Delivery or pickup, payment, and order confirmation will live here.';
  static const String checkoutYourOrder = 'Your order';
  static const String checkoutSelectMethod =
      'Choose pickup or delivery to continue.';
  static const String checkoutMethodUnavailable =
      'That fulfillment option is not available right now.';
  static const String checkoutDeliveryAddressRequired =
      'Enter a full delivery address to continue.';
  static const String checkoutScheduleRequired =
      'Pick a day and time for your scheduled order.';
  static const String checkoutScheduleInPast =
      'Choose a time that is still upcoming.';
  static const String checkoutRecordHint =
      'Rechael will fulfill delivery manually — self-delivery, a third-party '
      'service, or another arrangement. No rider tracking in the app yet.';
  static const String placeOrder = 'Place order';
  static const String fulfillmentSectionTitle = 'Fulfillment';
  static const String fulfillmentHowToReceive = 'How do you want your order?';
  static const String fulfillmentPickup = 'Pickup';
  static const String fulfillmentDelivery = 'Delivery';
  static const String orderTimingTitle = 'Order timing';
  static const String orderTimingAsap = 'ASAP';
  static const String orderTimingAsapBody =
      'We will prepare your order as soon as we can.';
  static const String orderTimingSchedule = 'Schedule order';
  static const String orderTimingScheduleBody =
      'Choose a day and time — helpful when meals are prepared in batches.';
  static const String orderTimingPickSlot = 'Choose day & time';
  static const String orderTimingChangeSlot = 'Change day & time';
  static const String paymentTitle = 'Payment';
  static const String paymentSecureHeadline = 'Pay securely with Stripe';
  static const String paymentSecureBody =
      'Card details are handled by Stripe — RechEats never stores them in '
      'Firebase. Apple Pay and Google Pay appear when your device supports them.';
  static const String paymentMethodCard = 'Credit / debit card';
  static const String paymentMethodApplePay = 'Apple Pay';
  static const String paymentMethodGooglePay = 'Google Pay';
  static const String paymentCanceled = 'Payment canceled. Your order was not placed.';
  static const String paymentRequired = 'Complete payment to place your order.';
  static const String payAndPlaceOrder = 'Pay & place order';
  static String orderConfirmedTiming(String label) => 'Timing: $label';
  static String checkoutQtyPrice(int qty, String price) =>
      '${qty}× · $price';
  static const String fulfillmentNoneAvailable =
      'Pickup and delivery are both turned off right now. Check back soon.';
  static String pickupReadyMessage(String location) =>
      'Your order will be ready for pickup at $location.';
  static const String deliveryDetailsTitle = 'Delivery details';
  static const String deliveryUseSavedAddress = 'Saved addresses';
  static const String apartmentUnit = 'Apartment / unit';
  static const String deliveryInstructions = 'Delivery instructions';
  static const String deliveryInstructionsHint =
      'Gate code, landmark, or leave at door…';
  static String deliveryOrderRecordedMessage(String address) =>
      address.trim().isEmpty
          ? 'Your delivery order has been recorded.'
          : 'Your delivery order has been recorded for $address.';
  static const String orderConfirmedTitle = 'Confirmation';
  static const String orderConfirmedHeadline = 'Order Confirmed! 🎉';
  static String orderConfirmedNumber(String code) => 'Order #$code';
  static const String orderConfirmedThanks =
      'Thank you for ordering from RechEats.';
  static const String orderConfirmedItems = 'Items';
  static const String orderConfirmedFulfillment = 'Pickup / delivery';
  static const String orderConfirmedPrepTime = 'Expected preparation time';
  static const String orderConfirmedStatus = 'Order status';
  static String orderConfirmedTotal(String amount) => 'Total $amount';
  static const String trackOrder = 'Track Order';
  static const String trackOrderTitle = 'Track order';
  static const String trackOrderSubtitle =
      'We\'ll update this as your order moves through the kitchen.';
  static const String trackOrderSubtitlePickup =
      'Status updates as your order is prepared for pickup. No GPS tracking.';
  static const String trackOrderSubtitleDelivery =
      'Status updates as your order is prepared and sent out. No rider map yet.';
  static const String backToMenu = 'Back to menu';

  static const String feedbackTitle = 'How was your RechEats experience?';
  static const String feedbackCommentLabel = 'Tell us what you think';
  static const String feedbackCommentHint =
      'Optional — your note goes privately to Rechael.';
  static const String feedbackSubmit = 'Send feedback';
  static const String feedbackSending = 'Sending…';
  static const String feedbackSkip = 'Not now';
  static const String feedbackThanks =
      'Thanks! Your feedback was sent to Rechael.';
  static const String feedbackRateCta = 'Rate your experience';
  static const String feedbackShareCta = 'Share feedback';

  static const String fulfillmentSettings = 'Pickup & delivery';
  static const String fulfillmentSettingsMenuSubtitle =
      'Turn pickup and delivery on or off for customers';
  static const String fulfillmentSettingsSubtitle =
      'Choose how customers can receive orders. Delivery is recorded in the '
      'app — you fulfill it yourself, with a third party, or manually.';
  static const String fulfillmentSettingsTitle = 'Fulfillment';
  static const String fulfillmentOfferPickup = 'Offer pickup';
  static const String fulfillmentOfferPickupBody =
      'Customers pick up at your kitchen location.';
  static const String fulfillmentOfferDelivery = 'Offer delivery';
  static const String fulfillmentOfferDeliveryBody =
      'Customers provide an address. You arrange delivery outside the app.';
  static const String fulfillmentPickupLocationLabel = 'Pickup location';
  static const String fulfillmentPickupLocationHint = 'Street or neighborhood';
  static const String fulfillmentPickupLocationRequired =
      'Enter a pickup location.';
  static const String fulfillmentDeliveryFeeLabel = 'Delivery fee';
  static const String fulfillmentDeliveryFeeInvalid =
      'Enter a valid delivery fee.';
  static const String fulfillmentDeliveryManualHint =
      'No rider system yet — delivery orders are recorded for you to fulfill.';
  static const String fulfillmentNeedOneMethod =
      'Enable pickup, delivery, or both.';
  static const String fulfillmentSettingsSaved = 'Fulfillment settings saved';

  static const String menuItemUnavailable = 'Currently unavailable';
  static const String menuItemUnavailableBody =
      'This dish is sold out for now. Check back later — it stays on the menu.';
  static const String preparationTime = 'Prep time';
  static const String customizeYourMeal = 'Customize your meal';
  static const String requiredChoice = 'Required';
  static const String optionalChoice = 'Optional';
  static const String selectOption = 'Choose one';
  static const String addOnsTitle = 'Add-ons';
  static const String portionSizeTitle = 'Portion size';
  static const String ingredientsTitle = 'Ingredients';
  static const String allergensTitle = 'Allergen information';
  static const String quantityTitle = 'Quantity';
  static const String specialInstructionsTitle = 'Special instructions';
  static const String specialInstructionsHint =
      'Please make the soup extra spicy.';
  static const String itemTotal = 'Total';
  static String prepMinutes(int minutes) => '$minutes min prep';

  static const String manageMenu = 'Manage menu';
  static const String manageMenuSubtitle =
      'Mark dishes available or sold out without deleting them';
  static const String manageMenuTitle = 'Kitchen menu';
  static const String availableLabel = 'Available';
  static const String unavailableLabel = 'Unavailable';
  static const String availabilityUpdated = 'Availability updated';
  static const String menuEmptyTitle = 'No dishes yet';
  static const String menuEmptyBody =
      'When Rechael adds meals, they will appear here.';

  static const String profileTitle = 'Profile';
  static const String profileGuestTitle = 'Sign in to manage your profile';
  static const String profileGuestBody =
      'Save your details, addresses, and favorites so checkout stays quick.';
  static const String editProfile = 'Edit profile';
  static const String editProfileSubtitle = 'Name, phone, email, and photo';
  static const String phoneLabel = 'Phone number';
  static const String emailChangeHelper =
      'Changing email sends a verification link to the new address.';
  static const String saveChanges = 'Save changes';
  static const String profileSaved = 'Profile updated';
  static const String choosePhoto = 'Choose photo';
  static const String removePhoto = 'Remove photo';
  static const String photoUpdated = 'Profile photo updated';
  static const String photoRemoved = 'Profile photo removed';

  static const String savedAddresses = 'Saved addresses';
  static const String savedAddressesEmptyHint = 'Add a delivery address';
  static const String savedAddressesEmptyTitle = 'No saved addresses';
  static const String savedAddressesEmptyBody =
      'Add a home or work address so delivery checkout is faster.';
  static const String addAddress = 'Add address';
  static const String editAddress = 'Edit address';
  static const String saveAddress = 'Save address';
  static const String addressLabel = 'Address type';
  static const String addressLabelHome = 'Home';
  static const String addressLabelWork = 'Work';
  static const String addressLabelOther = 'Other';
  static const String streetAddress = 'Street address';
  static const String apartmentOptional = 'Apartment / unit (optional)';
  static const String cityLabel = 'City';
  static const String stateLabel = 'State';
  static const String zipLabel = 'ZIP';
  static const String zipHint = '20850';
  static const String stateHint = 'MD';
  static const String cityHint = 'Rockville';
  static const String defaultAddress = 'Default';
  static const String defaultAddressHelper =
      'Use this address first at checkout.';
  static const String addressSaved = 'Address saved';
  static const String addressUpdated = 'Address updated';
  static const String addressDeleted = 'Address deleted';
  static const String deleteAddressTitle = 'Delete address?';
  static String deleteAddressBody(String label) =>
      'Remove "$label" from your saved addresses?';
  static const String delete = 'Delete';
  static const String cancel = 'Cancel';

  static const String orderHistory = 'Order history';
  static const String orderHistoryEmptyTitle = 'No orders yet';
  static const String orderHistoryEmptyBody =
      'When you place an order, it will show up here.';
  static const String currentOrder = 'Current order';
  static const String currentOrders = 'Current orders';
  static const String previousOrders = 'Previous orders';
  static const String orderAgain = 'Order again';
  static const String orderAgainAdded = 'Items added to your cart';
  static const String orderHistoryDate = 'Date';
  static const String orderHistoryItems = 'Items';
  static const String orderHistoryStatus = 'Status';
  static const String favorites = 'My Favorites';
  static const String favoritesEmptyTitle = 'No favorites yet';
  static const String favoritesEmptyBody =
      'Tap the heart on meals you love to find your preferred Nigerian dishes faster.';
  static const String favoritesSignInRequired =
      'Sign in to save favorites and find them quickly next time.';
  static const String addToFavorites = 'Add to favorites';
  static const String removeFromFavorites = 'Remove from favorites';
  static const String favoriteAdded = 'Saved to My Favorites';
  static const String favoriteRemoved = 'Removed from My Favorites';
  static String favoriteAddedNamed(String name) =>
      '$name — saved to My Favorites';
  static String favoriteRemovedNamed(String name) =>
      '$name — removed from My Favorites';
  static String favoritesCount(int count) =>
      count == 1 ? '1 saved dish' : '$count saved dishes';
  static const String notifications = 'Notifications';
  static const String notifOrderUpdates = 'Order updates';
  static const String notifOrderUpdatesBody =
      'Status changes for pickup and delivery.';
  static const String notifPromotions = 'Offers & promotions';
  static const String notifPromotionsBody =
      'Occasional specials from RechEats.';
  static const String help = 'Help';
  static const String customerSupport = 'Customer Support';
  static const String supportContactSection = 'Contact RechEats';
  static const String supportCall = 'Call';
  static const String supportEmail = 'Email';
  static const String supportWhatsApp = 'WhatsApp';
  static const String supportReportSection = 'Report an Order Problem';
  static const String supportReportSubtitle =
      'Tell us what went wrong and we\'ll help sort it out.';
  static const String supportProblemMissing = 'Missing item';
  static const String supportProblemWrong = 'Wrong item';
  static const String supportProblemLate = 'Late order';
  static const String supportProblemPayment = 'Payment issue';
  static const String supportProblemOther = 'Other';
  static const String supportLaunchFailed =
      'Couldn\'t open that app. Try another contact option.';
  static String supportReportSubject(String issue) =>
      'RechEats order problem: $issue';
  static String supportReportBody(String issue) =>
      'Hi RechEats,\n\nI need help with an order.\n\nIssue: $issue\n\n'
      'Order number (if you have it):\n\nThanks';
  static const String helpKitchen = 'Rechael\'s kitchen';
  static const String helpHoursTitle = 'Ordering hours';
  static const String helpHoursBody =
      'Check the app when you browse — hours can vary by day.';
  static const String helpContactTitle = 'Need help with an order?';
  static const String helpContactBody =
      'Use the details on your order receipt, or message RechEats support.';
  static const String helpFaqTitle = 'Common questions';
  static const String helpFaq1Q = 'Do you deliver?';
  static const String helpFaq1A =
      'Yes — choose delivery or pickup at checkout when ordering.';
  static const String helpFaq2Q = 'Can I save an address?';
  static const String helpFaq2A =
      'Yes. Open Profile → Saved addresses to add home, work, and more.';
  static const String helpFaq3Q = 'How do I update my phone or email?';
  static const String helpFaq3A =
      'Open Profile → Edit profile to change your contact details.';
}
