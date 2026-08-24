# RechEats Cloud Functions

## Module 13 — Stripe PaymentIntents (US)

Stripe PaymentIntents for the US market (Rockville, MD). Card PANs never
touch Firebase — only `paymentIntentId` + status are stored on orders.

### Setup

1. Create a Stripe account and enable **Apple Pay** / **Google Pay** in the Dashboard.
2. Set the secret (server only):

   ```bash
   firebase functions:secrets:set STRIPE_SECRET_KEY
   ```

3. From `functions/`:

   ```bash
   npm install
   npm run build
   firebase deploy --only functions:createPaymentIntent
   ```

4. Run the Flutter app with:

   ```bash
   flutter run \
     --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_... \
     --dart-define=STRIPE_MERCHANT_IDENTIFIER=merchant.org.recheats \
     --dart-define=PAYMENT_BACKEND_URL=https://us-east1-recheats.cloudfunctions.net/createPaymentIntent
   ```

Apple Pay also requires registering `merchant.org.recheats` in Apple Developer
and linking it in the Stripe Dashboard + Xcode capability.

## Module 16 — Order status push (FCM)

`onOrderStatusChanged` watches `orders/{orderId}` and sends Firebase Cloud
Messaging when `status` advances. Customer copy:

| Status | Body |
|--------|------|
| `confirmed` | Your order has been confirmed. |
| `preparing` | Your order is being prepared. |
| `ready` | Your order is ready for pickup. |
| `outForDelivery` | Your order is on its way. |
| `delivered` / `completed` | Your order has been delivered. Enjoy your meal! ❤️ |

Tokens live on `users/{uid}.fcmTokens` (written by the Flutter app after login).
Sends are skipped when `users/{uid}.notifications.orderUpdates` is `false`.

### Deploy

```bash
cd functions
npm install
npm run build
firebase deploy --only functions:onOrderStatusChanged
```

### Client checklist

1. Run with Firebase enabled (`USE_FIREBASE=true` and `DefaultFirebaseOptions.isConfigured`).
2. Android: `POST_NOTIFICATIONS` + channel `recheats_orders` (created in `MainActivity`).
3. iOS: add `GoogleService-Info.plist`, enable Push Notifications in Xcode, upload an APNs key to Firebase Console.
