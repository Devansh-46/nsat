import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

/**
 * sendNotification — sends FCM push to a topic.
 *
 * FIXES Issue #37: Added admin auth check so only users with the
 * `admin` custom claim can invoke this function.
 */
export const sendNotification = onCall(
  { region: "asia-south1", consumeAppCheckToken: true },
  async (request) => {
    // SECURITY: require admin custom claim
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }
    if (request.auth.token.admin !== true) {
      throw new HttpsError("permission-denied", "Admin access required");
    }

    const db = admin.firestore();
    const title = request.data?.title as string | undefined;
    const body = request.data?.body as string | undefined;
    const target = (request.data?.target as string) ?? "all";

    if (!title || !body) {
      throw new HttpsError(
        "invalid-argument",
        "title and body are required"
      );
    }

    const topic = target === "all"
      ? "all_students"
      : `school_${target}`;

    try {
      const message: admin.messaging.Message = {
        notification: {
          title,
          body,
        },
        topic,
        android: {
          priority: "high" as const,
          notification: {
            channelId: "nsat_notifications",
            priority: "high" as const,
          },
        },
        apns: {
          headers: {
            "apns-priority": "10",
          },
          payload: {
            aps: {
              alert: {
                title,
                body,
              },
              sound: "default",
              contentAvailable: true,
            },
          },
        },
      };

      const response = await admin.messaging().send(message);
      console.log(`FCM sent to topic '${topic}' by ${request.auth.uid}: ${response}`);

      await db.collection("notifications").add({
        title,
        body,
        target,
        topic,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        sentBy: request.auth.uid,
        fcmResponse: response,
      });

      return { success: true, topic, messageId: response };
    } catch (error) {
      console.error("FCM send failed:", error);
      throw new HttpsError("internal", "Failed to send notification");
    }
  }
);
