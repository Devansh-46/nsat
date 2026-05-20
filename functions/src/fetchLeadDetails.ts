import { onCall, HttpsError } from "firebase-functions/v2/https";
import fetch from "node-fetch";
import { NPF_ACCESS_KEY, NPF_SECRET_KEY, NPF_BASE_URL, mapCourseKey }
  from "./config";

/**
 * Callable: fetches a student's details from NPF API 2 by lead_id.
 *
 * Called by the Flutter app after the fee gate passes.
 * Returns: { name, courseKey, email, mobile, leadId }
 *
 * The NPF `course` display string is mapped to canonical key before
 * returning — the app never sees the raw NPF string.
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

    try {
      // NPF API 2: get lead details by lead_id
      const url =
        `${NPF_BASE_URL}/lead/${leadId}` +
        `?access-key=${encodeURIComponent(NPF_ACCESS_KEY)}` +
        `&secret-key=${encodeURIComponent(NPF_SECRET_KEY)}`;
      const response = await fetch(url, {
        method: "GET",
        headers: {
          "Content-Type": "application/json",
        },
      });

      if (!response.ok) {
        throw new HttpsError(
          "unavailable",
          `NPF API returned ${response.status}`
        );
      }

      const body = await response.json() as {
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
      if (error instanceof HttpsError) throw error;
      console.error("fetchLeadDetails error:", error);
      throw new HttpsError("internal", "Failed to fetch lead details");
    }
  }
);