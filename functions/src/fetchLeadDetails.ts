import { onCall, HttpsError } from "firebase-functions/v2/https";
import fetch from "node-fetch";
import { NPF_ACCESS_KEY, NPF_SECRET_KEY, NPF_BASE_URL, mapCourseKey }
  from "./config";

/**
 * Callable: fetches a student's details from NPF API by lead_id.
 *
 * Endpoint: POST /lead/v1/getDetailsById
 * Body: { lead_id, fields: [...] }
 * Returns: { name, courseKey, email, mobile, leadId }
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
      });

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
      if (error instanceof HttpsError) throw error;
      console.error("fetchLeadDetails error:", error);
      throw new HttpsError("internal", "Failed to fetch lead details");
    }
  }
);