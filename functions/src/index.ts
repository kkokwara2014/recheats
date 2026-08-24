import cors from "cors";
import express from "express";
import * as admin from "firebase-admin";
import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import Stripe from "stripe";

// Initialize once for Messaging + Firestore (order pushes).
if (admin.apps.length === 0) {
  admin.initializeApp();
}

export { onOrderStatusChanged } from "./order_notifications";

/**
 * Stripe secret key — set with:
 *   firebase functions:secrets:set STRIPE_SECRET_KEY
 * Never put this in the Flutter app or commit it to git.
 */
const stripeSecretKey = defineSecret("STRIPE_SECRET_KEY");

const app = express();
app.use(cors({ origin: true }));
app.use(express.json());

type CreateIntentBody = {
  amount?: number;
  currency?: string;
  orderId?: string;
  customerEmail?: string;
  customerName?: string;
  description?: string;
};

app.post("/", async (req, res) => {
  try {
    const body = (req.body ?? {}) as CreateIntentBody;
    const amount = Number(body.amount);
    const currency = (body.currency ?? "usd").toLowerCase();

    if (!Number.isFinite(amount) || amount < 50) {
      res.status(400).json({
        error: "amount must be an integer >= 50 (USD cents).",
      });
      return;
    }
    if (currency !== "usd") {
      res.status(400).json({ error: "Only usd is supported for RechEats." });
      return;
    }

    const stripe = new Stripe(stripeSecretKey.value());

    const intent = await stripe.paymentIntents.create({
      amount: Math.round(amount),
      currency,
      // Card + wallets; PaymentSheet enables Apple Pay / Google Pay on device.
      automatic_payment_methods: { enabled: true },
      description: body.description ?? "RechEats order",
      receipt_email: body.customerEmail,
      metadata: {
        ...(body.orderId ? { orderId: body.orderId } : {}),
        ...(body.customerName ? { customerName: body.customerName } : {}),
        app: "recheats",
        market: "US",
      },
    });

    // Client-safe payload only — never return the secret key.
    res.status(200).json({
      paymentIntentId: intent.id,
      clientSecret: intent.client_secret,
    });
  } catch (error) {
    console.error("createPaymentIntent failed", error);
    res.status(500).json({ error: "Unable to create payment intent." });
  }
});

export const createPaymentIntent = onRequest(
  {
    region: "us-east1",
    secrets: [stripeSecretKey],
  },
  app,
);
