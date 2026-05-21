import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as crypto from "crypto";
import * as nodemailer from "nodemailer";
import { SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, OTP_FROM_NAME }
  from "./config";

// OTP validity: 10 minutes
const OTP_EXPIRY_MS = 10 * 60 * 1000;

function generateOtp(): string {
  return crypto.randomInt(100000, 999999).toString();
}

function hashOtp(code: string): string {
  return crypto.createHash("sha256").update(code).digest("hex");
}

/**
 * sendOtp — generates a 6-digit code, hashes it into `otps/{applicationNo}`,
 * and emails the plain code to the student.
 */
export const sendOtp = onCall(
  { region: "asia-south1" },
  async (request) => {
    const db = admin.firestore();
    const applicationNo = request.data?.application_no as string | undefined;
    const email = request.data?.email as string | undefined;
    const studentName = request.data?.name as string | undefined;

    if (!applicationNo || !email) {
      throw new HttpsError(
        "invalid-argument",
        "application_no and email are required"
      );
    }

    const code = generateOtp();
    const hashed = hashOtp(code);
    const expiresAt = Date.now() + OTP_EXPIRY_MS;

    // Write hashed OTP to Firestore
    await db.collection("otps").doc(applicationNo).set({
      hashedCode: hashed,
      expiresAt,
      attempts: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Send email
    try {
      const transporter = nodemailer.createTransport({
        host: SMTP_HOST,
        port: SMTP_PORT,
        secure: SMTP_PORT === 465,
        auth: { user: SMTP_USER, pass: SMTP_PASS },
      });

      await transporter.sendMail({
        from: `"${OTP_FROM_NAME}" <${SMTP_USER}>`,
        to: email,
        subject: "NSAT Verification Code",
        text:
          `Dear ${studentName ?? "Student"},\n\n` +
          `Your NSAT verification code is: ${code}\n\n` +
          `This code is valid for 10 minutes.\n\n` +
          `If you did not request this, please ignore this email.\n\n` +
          `— Noida International University`,
        html:
          `<p>Dear ${studentName ?? "Student"},</p>` +
          `<p>Your NSAT verification code is:</p>` +
          `<h2 style="letter-spacing:4px;font-family:monospace">${code}</h2>` +
          `<p>This code is valid for 10 minutes.</p>` +
          `<p style="color:#888">If you did not request this, ` +
          `please ignore this email.</p>` +
          `<p>— Noida International University</p>`,
      });

      console.log(`OTP sent to ${email} for ${applicationNo}`);
      return { success: true };
    } catch (error) {
      console.error("Email send failed:", error);
      // Clean up the OTP doc since email failed
      await db.collection("otps").doc(applicationNo).delete();
      throw new HttpsError("internal", "Failed to send verification email");
    }
  }
);

/**
 * verifyOtp — checks the submitted code against the hashed one in Firestore.
 * Max 5 attempts; expired codes are rejected.
 */
export const verifyOtp = onCall(
  { region: "asia-south1" },
  async (request) => {
    const db = admin.firestore();
    const applicationNo = request.data?.application_no as string | undefined;
    const code = request.data?.code as string | undefined;

    if (!applicationNo || !code) {
      throw new HttpsError(
        "invalid-argument",
        "application_no and code are required"
      );
    }

    const docRef = db.collection("otps").doc(applicationNo);
    const doc = await docRef.get();

    if (!doc.exists) {
      throw new HttpsError("not-found", "No OTP found — request a new one");
    }

    const data = doc.data()!;
    const attempts = (data.attempts ?? 0) as number;

    // Too many attempts
    if (attempts >= 5) {
      await docRef.delete();
      throw new HttpsError(
        "resource-exhausted",
        "Too many attempts — request a new code"
      );
    }

    // Expired
    if (Date.now() > (data.expiresAt as number)) {
      await docRef.delete();
      throw new HttpsError(
        "deadline-exceeded",
        "Code has expired — request a new one"
      );
    }

    // Check
    const hashed = hashOtp(code);
    if (hashed !== data.hashedCode) {
      await docRef.update({
        attempts: admin.firestore.FieldValue.increment(1),
      });
      const remaining = 4 - attempts;
      throw new HttpsError(
        "permission-denied",
        `Incorrect code. ${remaining} attempt${remaining !== 1 ? "s" : ""} remaining.`
      );
    }

    // Valid — delete the OTP doc
    await docRef.delete();
    console.log(`OTP verified for ${applicationNo}`);
    return { verified: true };
  }
);