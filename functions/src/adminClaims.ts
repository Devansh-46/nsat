import * as crypto from "crypto";
import * as nodemailer from "nodemailer";

import { onCall, HttpsError, CallableRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { ROOT_SUPERADMIN_EMAIL } from "./admin_claims_config";
import { SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, OTP_FROM_NAME } from "./config";

const db = admin.firestore();

const ADMINS_COLLECTION = "admins";
const SUPERADMINS_COLLECTION = "superadmins";

function assertSuperadmin(request: CallableRequest): void {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required");
  }
  if (request.auth.token.superAdmin !== true) {
    throw new HttpsError("permission-denied", "Super admin access required");
  }
}

async function isSuperadminEmail(email: string): Promise<boolean> {
  if (email === ROOT_SUPERADMIN_EMAIL) return true;
  const doc = await db.collection(SUPERADMINS_COLLECTION).doc(email).get();
  return doc.exists;
}

export const setAdminClaim = onCall(
  { region: "asia-south1" },
  async (request) => {
    assertSuperadmin(request);

    const email = (request.data?.email as string | undefined)?.trim().toLowerCase();
    if (!email) {
      throw new HttpsError("invalid-argument", "email is required");
    }

    try {
      let user: admin.auth.UserRecord;
      let tempPassword: string | null = null;
      try {
        user = await admin.auth().getUserByEmail(email);
      } catch (_) {
        tempPassword = crypto.randomBytes(4).toString("hex");
        user = await admin.auth().createUser({
          email,
          password: tempPassword,
          displayName: email.split("@")[0],
          emailVerified: true,
        });
        console.log(`Created new Auth user: ${email} (UID: ${user.uid})`);
      }

      const isSuper = await isSuperadminEmail(email);
      const role = isSuper ? "superAdmin" : "admin";

      if (isSuper) {
        await admin.auth().setCustomUserClaims(user.uid, {
          admin: true,
          superAdmin: true,
        });
        console.log(`Superadmin claim set for ${email}`);
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

export const promoteSuperadmin = onCall(
  { region: "asia-south1" },
  async (request) => {
    assertSuperadmin(request);

    const email = (request.data?.email as string | undefined)?.trim().toLowerCase();
    if (!email) {
      throw new HttpsError("invalid-argument", "email is required");
    }
    if (email === ROOT_SUPERADMIN_EMAIL) {
      throw new HttpsError("permission-denied", "Root superadmin cannot be modified");
    }

    const adminDoc = await db.collection(ADMINS_COLLECTION).doc(email).get();
    if (!adminDoc.exists) {
      throw new HttpsError("failed-precondition", "User must be an admin first");
    }

    const user = await admin.auth().getUserByEmail(email);

    await db.collection(SUPERADMINS_COLLECTION).doc(email).set({
      email,
      addedBy: request.auth!.token.email ?? request.auth!.uid,
      addedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await admin.auth().setCustomUserClaims(user.uid, {
      admin: true,
      superAdmin: true,
    });

    console.log(`Promoted ${email} to superadmin by ${request.auth!.token.email}`);
    return { success: true };
  }
);

export const demoteSuperadmin = onCall(
  { region: "asia-south1" },
  async (request) => {
    assertSuperadmin(request);

    const email = (request.data?.email as string | undefined)?.trim().toLowerCase();
    if (!email) {
      throw new HttpsError("invalid-argument", "email is required");
    }
    if (email === ROOT_SUPERADMIN_EMAIL) {
      throw new HttpsError("permission-denied", "Cannot demote the root superadmin");
    }
    if (email === (request.auth!.token.email as string | undefined)?.toLowerCase()) {
      throw new HttpsError("permission-denied", "Cannot demote yourself");
    }

    const user = await admin.auth().getUserByEmail(email);

    await db.collection(SUPERADMINS_COLLECTION).doc(email).delete();

    await admin.auth().setCustomUserClaims(user.uid, {
      admin: true,
      superAdmin: false,
    });

    console.log(`Demoted ${email} from superadmin by ${request.auth!.token.email}`);
    return { success: true };
  }
);

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

      await admin.auth().setCustomUserClaims(user.uid, {
        admin: false,
        superAdmin: false,
      });

      await db.collection(ADMINS_COLLECTION).doc(email).delete();
      await db.collection(SUPERADMINS_COLLECTION).doc(email).delete();

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

    if (await isSuperadminEmail(email)) {
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

    if (ROOT_SUPERADMIN_EMAIL) {
      admins.push({
        email: ROOT_SUPERADMIN_EMAIL,
        role: "superAdmin",
        addedBy: "root",
        allowedCourses: ["*"],
      });
    }

    const superSnap = await db.collection(SUPERADMINS_COLLECTION).get();
    for (const doc of superSnap.docs) {
      if (admins.some((a) => a.email === doc.id)) continue;
      const data = doc.data();
      admins.push({
        email: doc.id,
        role: "superAdmin",
        addedBy: data.addedBy ?? "unknown",
        addedAt: data.addedAt?.toDate?.()?.toISOString() ?? "",
        allowedCourses: ["*"],
      });
    }

    const snapshot = await db
      .collection(ADMINS_COLLECTION)
      .orderBy("addedAt", "desc")
      .get();

    for (const doc of snapshot.docs) {
      if (admins.some((a) => a.email === doc.id)) continue;
      const data = doc.data();
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
