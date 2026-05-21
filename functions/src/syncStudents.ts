import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import fetch from "node-fetch";
import { NPF_ACCESS_KEY, NPF_SECRET_KEY, NPF_BASE_URL } from "./config";

/**
 * Scheduled function: syncs students from NPF every 30 minutes.
 *
 * Uses NPF's POST-based application list API with pagination.
 * Writes/updates the `students` collection. Doc ID = application_no.
 */
export const syncStudents = onSchedule(
  {
    schedule: "every 30 minutes",
    region: "asia-south1",
    timeoutSeconds: 540,
    memory: "512MiB",
  },
  async () => {
    const db = admin.firestore();
    if (!NPF_ACCESS_KEY || !NPF_SECRET_KEY) {
      console.error("NPF credentials not set — skipping sync");
      return;
    }

    let totalSynced = 0;
    let page = 1;
    let hasMore = true;

    try {
      // Metadata doc — tracks last successful sync for logging
      const metaRef = db.collection("_meta").doc("npfSync");

      // Full sync every run: fetch all leads by payment status.
      // NPF doesn't support an updated_on filter, so we always
      // pull the full list and upsert. The dataset is small enough
      // (one form, fee-paid + pending only) that this is fast.
      const filters: Array<{ field: string; operator: string; value: unknown }> = [
        {
          field: "payment_status",
          operator: "equals",
          value: ["Payment Approved", "Payment Pending"],
        },
      ];

      console.log("Full sync: fetching all students by payment status");

      while (hasMore) {
        const url = `${NPF_BASE_URL}/application/v1/list`;
        const body = {
          page_size: 100,
          page: page,
          form_id: 22124,
          condition: "AND",
          filter: filters,
          fields: [
            "application_no",
            "payment_status",
            "lead_id",
          ],
        };

        const response = await fetch(url, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "access-key": NPF_ACCESS_KEY,
            "secret-key": NPF_SECRET_KEY,
          },
          body: JSON.stringify(body),
        });

        if (!response.ok) {
          console.error(
            `NPF API returned ${response.status} on page ${page}:`,
            await response.text()
          );
          return;
        }

        const rawText = await response.text();
        let result: Record<string, unknown>;
        try {
          result = JSON.parse(rawText) as Record<string, unknown>;
        } catch {
          console.error("NPF returned non-JSON:", rawText.substring(0, 500));
          return;
        }

        // Log the response structure on first page for debugging
        if (page === 1) {
          const keys = Object.keys(result);
          console.log("NPF response keys:", keys);
          const dataField = result["data"] as Record<string, unknown> | unknown[] | undefined;
          if (dataField) {
            console.log("result.data type:",
              Array.isArray(dataField) ? `array[${dataField.length}]` : typeof dataField);
            if (dataField && typeof dataField === "object" && !Array.isArray(dataField)) {
              console.log("result.data keys:", Object.keys(dataField));
              const innerData = (dataField as Record<string, unknown>)["data"];
              if (innerData) {
                console.log("result.data.data type:",
                  Array.isArray(innerData) ? `array[${(innerData as unknown[]).length}]` : typeof innerData);
              }
            }
          }
        }

        // NPF response shape: { code, status, message, data: { list: [...], pagination: {...} } }
        const dataField = result["data"];
        let list: Array<Record<string, unknown>> = [];
        if (dataField && typeof dataField === "object" && !Array.isArray(dataField)) {
          const inner = (dataField as Record<string, unknown>)["list"];
          if (Array.isArray(inner)) list = inner as Array<Record<string, unknown>>;
        } else if (Array.isArray(dataField)) {
          list = dataField as Array<Record<string, unknown>>;
        }

        if (list.length === 0) {
          console.log(`Page ${page}: 0 applicants — stopping`);
          hasMore = false;
          break;
        }

        // Batch writes (max 500 per batch)
        const batches: admin.firestore.WriteBatch[] = [];
        let currentBatch = db.batch();
        let count = 0;

        for (const applicant of list) {
          const appNo = applicant["application_no"] as string | undefined;
          if (!appNo) continue;

          const docRef = db.collection("students").doc(appNo);
          currentBatch.set(
            docRef,
            {
              application_no: appNo,
              payment_status: (applicant["payment_status"] as string) ?? "Payment Pending",
              lead_id: (applicant["lead_id"] as string) ?? "",
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

        totalSynced += count;

        // Check pagination from data.pagination
        const dField = result["data"] as Record<string, unknown> | undefined;
        const pagination = (dField && typeof dField === "object")
          ? (dField["pagination"] as Record<string, unknown> | undefined) : undefined;
        const lastPage = (pagination?.["last_page"] as number) ?? 1;
        const currentPage = (pagination?.["current_page"] as number) ?? page;
        if (currentPage >= lastPage || list.length < 100) {
          hasMore = false;
        } else {
          page++;
        }

        console.log(
          `Page ${page - (hasMore ? 1 : 0)}: synced ${count} students`
        );
      }

      console.log(`Total synced: ${totalSynced} students from NPF`);

      // Save sync timestamp for incremental sync next time
      await metaRef.set({
        lastSuccessfulSync: admin.firestore.FieldValue.serverTimestamp(),
        lastSyncCount: totalSynced,
      }, { merge: true });

    } catch (error) {
      console.error("NPF sync failed:", error);
    }
  }
);