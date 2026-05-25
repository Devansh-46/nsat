import * as crypto from "crypto";
import * as nodemailer from "nodemailer";

import { onCall, HttpsError, CallableRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { SUPERADMIN_EMAILS, ALLOWED_ADMIN_EMAILS } from "./admin_claims_config";
import { SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, OTP_FROM_NAME } from "./config";

const db = admin.firestore();

/**
 * Checks if the caller is authorized to manage admins.
 * Only superadmins (from .env) can add/remove admins.
 */
function assertSuperadmin(request: CallableRequest): void {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required");
  }
  if (request.auth.token.superAdmin !== true) {
    throw new HttpsError(
      "permission-denied",
      "Super admin access required"
    );
  }
}

/**
 * Checks if an email is in the superadmin allowlist from .env.
 */
function isSuperadminEmail(email: string): boolean {
  return SUPERADMIN_EMAILS.includes(email) || ALLOWED_ADMIN_EMAILS.includes(email);
}

/**
 * Firestore collection for regular admins.
 * Document ID = email (lowercase). Fields: { email, addedBy, addedAt }.
 */
const ADMINS_COLLECTION = "admins";

/**
 * setAdminClaim — grants admin access to a user.
 *
 * If the email is in the .env superadmin allowlist, they get { admin: true, superAdmin: true }.
 * Otherwise, the email is added to the Firestore `admins` collection and they get { admin: true }.
 *
 * Only existing superadmins can call this.
 */
export const setAdminClaim = onCall(
  { region: "asia-south1" },
  async (request) => {
    assertSuperadmin(request);

    const email = (request.data?.email as string | undefined)?.trim().toLowerCase();
    if (!email) {
      throw new HttpsError("invalid-argument", "email is required");
    }

    try {
      // Try to get existing user, or create a new one
      let user: admin.auth.UserRecord;
      let tempPassword: string | null = null;
      try {
        user = await admin.auth().getUserByEmail(email);
      } catch (_) {
        // User doesn't exist — create them with a short temp password
        tempPassword = crypto.randomBytes(4).toString("hex"); // 8 chars
        user = await admin.auth().createUser({
          email,
          password: tempPassword,
          displayName: email.split("@")[0],
          emailVerified: true,
        });
        console.log(`Created new Auth user: ${email} (UID: ${user.uid})`);
      }

      const role = isSuperadminEmail(email) ? "superAdmin" : "admin";

      if (role === "superAdmin") {
        await admin.auth().setCustomUserClaims(user.uid, {
          admin: true,
          superAdmin: true,
        });
        console.log(`Superadmin claim set for ${email} (via .env allowlist)`);
      } else {
        const adminDoc = {
          email,
          addedBy: request.auth!.uid,
          addedAt: admin.firestore.FieldValue.serverTimestamp(),
          forcePasswordChange: tempPassword ? true : false,
          allowedCourses: [],
        };
        await db.collection(ADMINS_COLLECTION).doc(email).set(adminDoc);

        await admin.auth().setCustomUserClaims(user.uid, {
          admin: true,
          superAdmin: false,
        });
        console.log(`Admin claim set for ${email} (via Firestore)`);
      }

      // Send credentials email if user was just created
      if (tempPassword) {
        try {
          const transporter = nodemailer.createTransport({
            host: SMTP_HOST,
            port: SMTP_PORT,
            secure: SMTP_PORT === 465,
            auth: { user: SMTP_USER, pass: SMTP_PASS },
          });

          const roleLabel = role === "superAdmin" ? "Super Administrator" : "Administrator";

          await transporter.sendMail({
            from: `"${OTP_FROM_NAME}" <${SMTP_USER}>`,
            to: email,
            subject: `NSAT Admin Access — ${roleLabel} Account Created`,
            text:
              `Dear ${email.split("@")[0]},\n\n` +
              `An admin account has been created for you on the NSAT (Noida International University Student Aptitude Test) admin dashboard.\n\n` +
              `Role: ${roleLabel}\n` +
              `Login URL: https://nsat.niu.edu.in\n` +
              `Email: ${email}\n` +
              `Temporary password: ${tempPassword}\n\n` +
              `Sign in at the Admin Login page. You will be asked to set a new password before accessing the dashboard.\n\n` +
              `If you did not expect this account, please ignore this email.\n\n` +
              `— Noida International University`,
            html:
              `<p>Dear ${email.split("@")[0]},</p>` +
              `<p>An admin account has been created for you on the <strong>NSAT</strong> (Noida International University Student Aptitude Test) admin dashboard.</p>` +
              `<table style="border-collapse:collapse;margin:16 0">` +
              `<tr><td style="padding:4 12;font-weight:600">Role</td><td style="padding:4 12">${roleLabel}</td></tr>` +
              `<tr><td style="padding:4 12;font-weight:600">Login URL</td><td style="padding:4 12"><a href="https://nsat.niu.edu.in">https://nsat.niu.edu.in</a></td></tr>` +
              `<tr><td style="padding:4 12;font-weight:600">Email</td><td style="padding:4 12">${email}</td></tr>` +
              `<tr><td style="padding:4 12;font-weight:600">Temporary password</td><td style="padding:4 12"><code style="background:#f0f0f0;padding:2 6;border-radius:4;font-size:14px">${tempPassword}</code></td></tr>` +
              `</table>` +
              `<div style="background:#fff3cd;border-left:4px solid #ffc107;padding:12 16;margin:16 0;border-radius:4px">` +
              `<strong>⚠️ Set your password on first login</strong><br/>` +
              `After signing in, you will be asked to create a new password before accessing the dashboard.` +
              `</div>` +
              `<p>Please sign in at the <strong>Admin Login</strong> page to get started.</p>` +
              `<p style="color:#888;font-size:13px">If you did not expect this account, please ignore this email.</p>` +
              `<p>— Noida International University</p>`,
          });

          console.log(`Credentials email sent to ${email}`);
        } catch (smtpError) {
          // Don't fail the whole operation if email fails — the user is still created
          console.error(`Failed to send credentials email to ${email}:`, smtpError);
        }
      }

      return { success: true, uid: user.uid, role };
    } catch (error) {
      console.error("Failed to set admin claim:", error);
      throw new HttpsError("internal", "Failed to set admin claim");
    }
  }
);

/**
 * removeAdminClaim — revokes admin access from a user.
 * Only superadmins can call this.
 */
export const removeAdminClaim = onCall(
  { region: "asia-south1" },
  async (request) => {
    assertSuperadmin(request);

    const email = (request.data?.email as string | undefined)?.trim().toLowerCase();
    if (!email) {
      throw new HttpsError("invalid-argument", "email is required");
    }

    try {
      const user = await admin.auth().getUserByEmail(email);

      // Remove admin claim
      await admin.auth().setCustomUserClaims(user.uid, {
        admin: false,
        superAdmin: false,
      });

      // Remove from Firestore admins collection if present
      await db.collection(ADMINS_COLLECTION).doc(email).delete();

      console.log(`Admin claim removed for ${email}`);
      return { success: true, uid: user.uid };
    } catch (error) {
      console.error("Failed to remove admin claim:", error);
      if ((error as { code?: string }).code === "auth/user-not-found") {
        throw new HttpsError("not-found", "User not found in Firebase Authentication.");
      }
      throw new HttpsError("internal", "Failed to remove admin claim");
    }
  }
);


/**
 * clearForcePasswordChange — called after the user changes their password.
 * Clears the flag in Firestore so next login allows direct dashboard access.
 */
export const clearForcePasswordChange = onCall(
  { region: "asia-south1" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    try {
      const email = request.auth.token.email as string | undefined;
      if (email) {
        await db.collection(ADMINS_COLLECTION).doc(email.toLowerCase()).update({
          forcePasswordChange: false,
        });
      }
      console.log(`forcePasswordChange cleared for ${email ?? request.auth.uid}`);
      return { success: true };
    } catch (error) {
      console.error("Failed to clear forcePasswordChange:", error);
      throw new HttpsError("internal", "Failed to update");
    }
  }
);

/**
 * updateAdminCourses — updates the allowed courses for a regular admin.
 * Only superadmins can call this.
 * Pass allowedCourses: ["*"] to grant access to all courses.
 */
export const updateAdminCourses = onCall(
  { region: "asia-south1" },
  async (request) => {
    assertSuperadmin(request);

    const email = (request.data?.email as string | undefined)?.trim().toLowerCase();
    const allowedCourses = request.data?.allowedCourses as string[] | undefined;

    if (!email) {
      throw new HttpsError("invalid-argument", "email is required");
    }
    if (!allowedCourses || !Array.isArray(allowedCourses)) {
      throw new HttpsError("invalid-argument", "allowedCourses array is required");
    }

    // Don't allow modifying superadmins via this endpoint
    if (isSuperadminEmail(email)) {
      throw new HttpsError("permission-denied", "Cannot modify superadmin course access");
    }

    try {
      const docRef = db.collection(ADMINS_COLLECTION).doc(email);
      const doc = await docRef.get();
      if (!doc.exists) {
        throw new HttpsError("not-found", "Admin not found");
      }

      await docRef.update({ allowedCourses });
      console.log(`Updated courses for ${email}: ${allowedCourses.join(", ")}`);
      return { success: true, allowedCourses };
    } catch (error) {
      console.error("Failed to update admin courses:", error);
      if (error instanceof HttpsError) throw error;
      throw new HttpsError("internal", "Failed to update course access");
    }
  }
);

/**
 * listAdmins — returns all regular admins from Firestore.
 * Also returns superadmins from .env (marked as role: "superAdmin").
 * Each admin includes their allowedCourses array.
 */
export const listAdmins = onCall(
  { region: "asia-south1" },
  async (request) => {
    if (!request.auth || !request.auth.token.admin) {
      throw new HttpsError("permission-denied", "Admin access required");
    }

    const admins: Array<{
      email: string;
      role: string;
      addedBy: string;
      addedAt?: string;
      allowedCourses: string[];
      forcePasswordChange?: boolean;
    }> = [];

    // Superadmins from .env — they get ["*"] (all courses)
    for (const email of [...SUPERADMIN_EMAILS, ...ALLOWED_ADMIN_EMAILS]) {
      admins.push({ email, role: "superAdmin", addedBy: "env", allowedCourses: ["*"] });
    }

    // Regular admins from Firestore
    const snapshot = await db
      .collection(ADMINS_COLLECTION)
      .orderBy("addedAt", "desc")
      .get();

    for (const doc of snapshot.docs) {
      const data = doc.data();
      if (admins.some((a) => a.email === doc.id)) continue;
      admins.push({
        email: doc.id,
        role: "admin",
        addedBy: data.addedBy ?? "unknown",
        addedAt: data.addedAt?.toDate?.()?.toISOString() ?? "",
        allowedCourses: (data.allowedCourses as string[]) ?? [],
        forcePasswordChange: (data.forcePasswordChange as boolean) ?? false,
      });
    }

    return { admins };
  }
);
