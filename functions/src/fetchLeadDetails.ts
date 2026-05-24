import { onCall, HttpsError } from "firebase-functions/v2/https";
import fetch from "node-fetch";
import AbortController from "abort-controller";
import { NPF_ACCESS_KEY, NPF_SECRET_KEY, NPF_BASE_URL, mapCourseKey }
  from "./config";

/**
 * Callable: fetches a student's details from NPF API by lead_id.
 *
 * FIXES Issue #36: Added AbortController timeout (10 seconds) on the
 * NPF API fetch call so the Cloud Function doesn't hang indefinitely.
 */
export const fetchLeadDetails = onCall(
  { region: "asia-south1" },
  async (request) => {
    const leadId = request.data?.lead_id as string | undefined;

    if (!leadId) {
      throw new HttpsError("invalid-argument", "lead_id is required");
    }
    if (!NPF_ACCESS_KEY || !NPF_SECRET_KEY) {
      throw new HttpsError(
        "failed-precondition",
        "NPF credentials not configured"
      );
    }

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 10_000); // 10s timeout

    try {
      const url = `${NPF_BASE_URL}/lead/v1/getDetailsById`;
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "access-key": NPF_ACCESS_KEY,
          "secret-key": NPF_SECRET_KEY,
        },
        body: JSON.stringify({
          lead_id: leadId,
          fields: ["name", "mobile", "lead_stage", "email", "course"],
        }),
        signal: controller.signal as unknown as AbortSignal,
      });

      clearTimeout(timeout);

      if (!response.ok) {
        console.error(`NPF lead API returned ${response.status}:`,
          await response.text());
        throw new HttpsError(
          "unavailable",
          `NPF API returned ${response.status}`
        );
      }

      const body = await response.json() as {
        code?: number;
        status?: boolean;
        data?: {
          details?: {
            name?: string;
            email?: string;
            mobile?: string;
            course?: string;
            lead_id?: string;
            lead_stage?: string;
          };
        };
      };

      const details = body.data?.details;
      if (!details) {
        throw new HttpsError("not-found", "Lead details not found in NPF");
      }

      const rawCourse = details.course ?? "";
      const courseKey = mapCourseKey(rawCourse);

      return {
        leadId: details.lead_id ?? leadId,
        name: details.name ?? "",
        courseKey,
        email: details.email ?? "",
        mobile: details.mobile ?? "",
      };
    } catch (error) {
      clearTimeout(timeout);
      if (error instanceof HttpsError) throw error;
      if ((error as Error).name === "AbortError") {
        console.error("NPF API request timed out for leadId:", leadId);
        throw new HttpsError("deadline-exceeded", "NPF API timed out. Please try again.");
      }
      console.error("fetchLeadDetails error:", error);
      throw new HttpsError("internal", "Failed to fetch lead details");
    }
  }
);
