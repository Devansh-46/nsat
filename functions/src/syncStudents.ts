import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import fetch from "node-fetch";
import { NPF_ACCESS_KEY, NPF_SECRET_KEY, NPF_BASE_URL } from "./config";

const db = admin.firestore();

/**
 * Scheduled function: syncs students from NPF API 1 every 30 minutes.
 *
 * NPF API 1 (application/v1/list) returns:
 *   - application_no
 *   - payment_status
 *   - lead_id
 *
 * Writes/updates the `students` collection. Doc ID = application_no.
 * Does NOT write name/course — those come from API 2 at login.
 */
export const syncStudents = onSchedule(
  {
    schedule: "every 30 minutes",
    region: "asia-south1",
    timeoutSeconds: 300,
    memory: "256MiB",
  },
  async () => {
    if (!NPF_ACCESS_KEY || !NPF_SECRET_KEY) {
      console.error("NPF credentials not set — skipping sync");
      return;
    }

    try {
      const url =
        `${NPF_BASE_URL}/application/v1/list` +
        `?access-key=${encodeURIComponent(NPF_ACCESS_KEY)}` +
        `&secret-key=${encodeURIComponent(NPF_SECRET_KEY)}`;
      const response = await fetch(url, {
        method: "GET",
        headers: {
          "Content-Type": "application/json",
        },
      });

      if (!response.ok) {
        console.error(`NPF API 1 returned ${response.status}`);
        return;
      }

      const body = await response.json() as {
        data?: Array<{
          application_no?: string;
          payment_status?: string;
          lead_id?: string;
        }>
      };

      const applicants = body.data ?? [];
      if (applicants.length === 0) {
        console.log("NPF returned 0 applicants — nothing to sync");
        return;
      }

      // Batch writes (max 500 per batch)
      const batches: admin.firestore.WriteBatch[] = [];
      let currentBatch = db.batch();
      let count = 0;

      for (const applicant of applicants) {
        const appNo = applicant.application_no;
        if (!appNo) continue;

        const docRef = db.collection("students").doc(appNo);
        currentBatch.set(
          docRef,
          {
            application_no: appNo,
            payment_status: applicant.payment_status ?? "Payment Pending",
            lead_id: applicant.lead_id ?? "",
            lastSyncedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );

        count++;
        if (count % 500 === 0) {
          batches.push(currentBatch);
          currentBatch = db.batch();
        }
      }

      batches.push(currentBatch);

      for (const batch of batches) {
        await batch.commit();
      }

      console.log(`Synced ${count} students from NPF`);
    } catch (error) {
      console.error("NPF sync failed:", error);
    }
  }
);