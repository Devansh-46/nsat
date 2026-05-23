import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

/**
 * sendNotification — sends FCM push to a topic.
 *
 * Targets:
 *   - "all"      → topic "all_students"
 *   - "set_ug"   → topic "school_set_ug"
 *   - "sbm_pg"   → topic "school_sbm_pg"
 *   etc.
 *
 * Also writes a record to `notifications` collection for history.
 */
export const sendNotification = onCall(
    { region: "asia-south1" },
    async (request) => {
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

        // Build the FCM topic name
        const topic = target === "all"
            ? "all_students"
            : `school_${target}`;

        try {
            // Send FCM message
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
            console.log(`FCM sent to topic '${topic}': ${response}`);

            // Write to notifications collection for history
            await db.collection("notifications").add({
                title,
                body,
                target,
                topic,
                sentAt: admin.firestore.FieldValue.serverTimestamp(),
                fcmResponse: response,
            });

            return { success: true, topic, messageId: response };
        } catch (error) {
            console.error("FCM send failed:", error);
            throw new HttpsError("internal", "Failed to send notification");
        }
    }
);