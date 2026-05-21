import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { ALLOWED_ADMIN_EMAILS } from "./config";

/**
 * setAdminClaim — sets the `admin` custom claim on a Firebase Auth user.
 * Requires caller to already have admin custom claim.
 */
export const setAdminClaim = onCall(
  { region: "asia-south1" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }
    if (request.auth.token.admin !== true) {
      throw new HttpsError("permission-denied", "Admin access required");
    }

    const email = request.data?.email as string | undefined;

    if (!email) {
      throw new HttpsError("invalid-argument", "email is required");
    }

    if (!ALLOWED_ADMIN_EMAILS.includes(email)) {
      throw new HttpsError(
        "permission-denied",
        "Email is not authorized for admin access"
      );
    }

    try {
      const user = await admin.auth().getUserByEmail(email);

      await admin.auth().setCustomUserClaims(user.uid, { admin: true });

      console.log(`Admin claim set for ${email}`);
      return { success: true, uid: user.uid };
    } catch (error) {
      console.error("Failed to set admin claim:", error);
      throw new HttpsError("internal", "Failed to set admin claim");
    }
  }
);

/**
 * removeAdminClaim — removes the `admin` custom claim from a Firebase Auth user.
 * Requires caller to already have admin custom claim.
 */
export const removeAdminClaim = onCall(
  { region: "asia-south1" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }
    if (request.auth.token.admin !== true) {
      throw new HttpsError("permission-denied", "Admin access required");
    }

    const email = request.data?.email as string | undefined;

    if (!email) {
      throw new HttpsError("invalid-argument", "email is required");
    }

    try {
      const user = await admin.auth().getUserByEmail(email);

      await admin.auth().setCustomUserClaims(user.uid, { admin: null });

      console.log(`Admin claim removed for ${email}`);
      return { success: true, uid: user.uid };
    } catch (error) {
      console.error("Failed to remove admin claim:", error);
      throw new HttpsError("internal", "Failed to remove admin claim");
    }
  }
);
