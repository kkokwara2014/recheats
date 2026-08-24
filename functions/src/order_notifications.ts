import * as admin from "firebase-admin";
import { logger } from "firebase-functions";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";

/**
 * Order status → customer push copy (Module 16).
 * Keep in sync with lib/features/notifications/domain/order_status_push.dart
 */
const ORDER_PUSH_BODIES: Record<string, string> = {
  confirmed: "Your order has been confirmed.",
  preparing: "Your order is being prepared.",
  ready: "Your order is ready for pickup.",
  outForDelivery: "Your order is on its way.",
  delivered: "Your order has been delivered. Enjoy your meal! ❤️",
  completed: "Your order has been delivered. Enjoy your meal! ❤️",
};

const ANDROID_CHANNEL_ID = "recheats_orders";

type UserDoc = {
  fcmTokens?: unknown;
  notifications?: {
    orderUpdates?: boolean;
  };
};

function asStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.filter((item): item is string => typeof item === "string" && item.length > 0);
}

/**
 * Sends RechEats FCM pushes when kitchen advances `orders/{orderId}.status`.
 */
export const onOrderStatusChanged = onDocumentUpdated(
  {
    document: "orders/{orderId}",
    region: "us-east1",
  },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const prevStatus = before.status as string | undefined;
    const nextStatus = after.status as string | undefined;
    if (!nextStatus || prevStatus === nextStatus) return;

    const body = ORDER_PUSH_BODIES[nextStatus];
    if (!body) {
      logger.info("No push copy for status", { nextStatus });
      return;
    }

    const userId = after.userId as string | undefined;
    if (!userId) {
      logger.warn("Order missing userId; skip push", {
        orderId: event.params.orderId,
      });
      return;
    }

    const userSnap = await admin.firestore().collection("users").doc(userId).get();
    if (!userSnap.exists) {
      logger.warn("User not found for order push", { userId });
      return;
    }

    const user = userSnap.data() as UserDoc;
    const orderUpdates = user.notifications?.orderUpdates !== false;
    if (!orderUpdates) {
      logger.info("User opted out of order updates", { userId });
      return;
    }

    const tokens = [...new Set(asStringArray(user.fcmTokens))];
    if (tokens.length === 0) {
      logger.info("No FCM tokens for user", { userId });
      return;
    }

    const orderId = event.params.orderId as string;
    const response = await admin.messaging().sendEachForMulticast({
      tokens,
      notification: {
        title: "RechEats",
        body,
      },
      data: {
        type: "order_status",
        orderId,
        status: nextStatus,
      },
      android: {
        priority: "high",
        notification: {
          channelId: ANDROID_CHANNEL_ID,
          sound: "default",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    });

    const staleTokens: string[] = [];
    response.responses.forEach((result, index) => {
      if (result.success) return;
      const code = result.error?.code;
      logger.warn("FCM send failed", {
        userId,
        orderId,
        code,
        message: result.error?.message,
      });
      if (
        code === "messaging/registration-token-not-registered" ||
        code === "messaging/invalid-registration-token"
      ) {
        staleTokens.push(tokens[index]!);
      }
    });

    if (staleTokens.length > 0) {
      await admin.firestore().collection("users").doc(userId).set(
        {
          fcmTokens: admin.firestore.FieldValue.arrayRemove(...staleTokens),
          fcmTokenUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }

    logger.info("Order status push sent", {
      orderId,
      nextStatus,
      successCount: response.successCount,
      failureCount: response.failureCount,
    });
  },
);
