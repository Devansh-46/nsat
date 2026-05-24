import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as crypto from "crypto";
import * as nodemailer from "nodemailer";
import {
  SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, OTP_FROM_NAME,
  TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_WHATSAPP_FROM
} from "./config";

// OTP validity: 10 minutes
const OTP_EXPIRY_MS = 10 * 60 * 1000;

// FIXES Issue #32: Use channel-specific sub-documents to prevent
// cross-channel OTP overwriting and attempt counter bypass.
// otps/{applicationNo}/channels/email
// otps/{applicationNo}/channels/whatsapp
const OTP_COLLECTION = "otps";
const CHANNELS_SUBCOLLECTION = "channels";

function generateOtp(): string {
  return crypto.randomInt(100000, 999999).toString();
}

function hashOtp(code: string): string {
  return crypto.createHash("sha256").update(code).digest("hex");
}

function getChannelRef(db: admin.firestore.Firestore, applicationNo: string, channel: string) {
  return db
    .collection(OTP_COLLECTION)
    .doc(applicationNo)
    .collection(CHANNELS_SUBCOLLECTION)
    .doc(channel);
}

/**
 * sendOtp — generates a 6-digit code, hashes it into
 * `otps/{applicationNo}/channels/email`, and emails the plain code.
 *
 * FIXES Issue #15: Added cooldown check — refuses resend if last send
 * was less than 60 seconds ago.
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

    const channelRef = getChannelRef(db, applicationNo, "email");

    // Cooldown check: prevent spam resends (60 second cooldown)
    const existing = await channelRef.get();
    if (existing.exists) {
      const data = existing.data()!;
      const createdAt = data.createdAtMs as number | undefined;
      if (createdAt && Date.now() - createdAt < 60_000) {
        const secondsLeft = Math.ceil((60_000 - (Date.now() - createdAt)) / 1000);
        throw new HttpsError(
          "resource-exhausted",
          `Please wait ${secondsLeft} seconds before requesting a new code.`
        );
      }
    }

    const code = generateOtp();
    const hashed = hashOtp(code);
    const expiresAt = Date.now() + OTP_EXPIRY_MS;

    // Write hashed OTP to channel-specific doc
    await channelRef.set({
      hashedCode: hashed,
      expiresAt,
      attempts: 0,
      channel: "email",
      createdAtMs: Date.now(),
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
      await channelRef.delete();
      throw new HttpsError("internal", "Failed to send verification email");
    }
  }
);

/**
 * verifyOtp — checks the submitted code against the hashed one.
 * Now requires a `channel` parameter to look up the correct sub-doc.
 *
 * FIXES Issue #16: Each channel (email/whatsapp) has its own OTP doc,
 * so verifying email code won't consume/fail due to whatsapp OTP overwrite.
 */
export const verifyOtp = onCall(
  { region: "asia-south1" },
  async (request) => {
    const db = admin.firestore();
    const applicationNo = request.data?.application_no as string | undefined;
    const code = request.data?.code as string | undefined;
    // REQUIRED now: caller must specify which channel they're verifying
    const channel = (request.data?.channel as string | undefined) ?? "email";

    if (!applicationNo || !code) {
      throw new HttpsError(
        "invalid-argument",
        "application_no and code are required"
      );
    }

    const channelRef = getChannelRef(db, applicationNo, channel);
    const doc = await channelRef.get();

    if (!doc.exists) {
      throw new HttpsError("not-found", "No OTP found — request a new one");
    }

    const data = doc.data()!;
    const attempts = (data.attempts ?? 0) as number;

    // Too many attempts (per channel)
    if (attempts >= 5) {
      await channelRef.delete();
      throw new HttpsError(
        "resource-exhausted",
        "Too many attempts — request a new code"
      );
    }

    // Expired
    if (Date.now() > (data.expiresAt as number)) {
      await channelRef.delete();
      throw new HttpsError(
        "deadline-exceeded",
        "Code has expired — request a new one"
      );
    }

    // Check
    const hashed = hashOtp(code);
    if (hashed !== data.hashedCode) {
      await channelRef.update({
        attempts: admin.firestore.FieldValue.increment(1),
      });
      const remaining = 4 - attempts;
      throw new HttpsError(
        "permission-denied",
        `Incorrect code. ${remaining} attempt${remaining !== 1 ? "s" : ""} remaining.`
      );
    }

    // Valid — delete the channel OTP doc
    await channelRef.delete();
    console.log(`OTP verified for ${applicationNo} (channel: ${channel})`);
    return { verified: true };
  }
);

/**
 * sendWhatsAppOtp — Twilio WhatsApp OTP delivery.
 *
 * FIXES:
 * - Issue #16: Writes to channel-specific doc so email OTP is never overwritten.
 * - Issue #15: 60-second cooldown check.
 * - Issue #36: AbortController timeout on NPF/Twilio API calls.
 */
export const sendWhatsAppOtp = onCall(
  { region: "asia-south1" },
  async (request) => {
    const db = admin.firestore();
    const applicationNo = request.data?.application_no as string | undefined;
    const rawPhone = request.data?.phone as string | undefined;
    const studentName = request.data?.name as string | undefined;

    if (!applicationNo || !rawPhone) {
      throw new HttpsError("invalid-argument", "application_no and phone are required");
    }

    if (!TWILIO_ACCOUNT_SID || !TWILIO_AUTH_TOKEN || !TWILIO_WHATSAPP_FROM) {
      console.error("[sendWhatsAppOtp] Twilio env vars not set");
      throw new HttpsError("failed-precondition", "WhatsApp service is not configured");
    }

    let phone = rawPhone.trim();
    if (!phone.startsWith("+")) {
      phone = "+91" + phone;
    }

    const channelRef = getChannelRef(db, applicationNo, "whatsapp");

    // Cooldown check
    const existing = await channelRef.get();
    if (existing.exists) {
      const data = existing.data()!;
      const createdAt = data.createdAtMs as number | undefined;
      if (createdAt && Date.now() - createdAt < 60_000) {
        const secondsLeft = Math.ceil((60_000 - (Date.now() - createdAt)) / 1000);
        throw new HttpsError(
          "resource-exhausted",
          `Please wait ${secondsLeft} seconds before requesting a new code.`
        );
      }
    }

    const code = generateOtp();
    const hashed = hashOtp(code);
    const expiresAt = Date.now() + OTP_EXPIRY_MS;

    // Write to whatsapp-specific channel doc — email OTP is untouched
    await channelRef.set({
      hashedCode: hashed,
      expiresAt,
      attempts: 0,
      channel: "whatsapp",
      phone,
      createdAtMs: Date.now(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const twilioUrl =
      `https://api.twilio.com/2010-04-01/Accounts/${TWILIO_ACCOUNT_SID}/Messages.json`;

    const body = new URLSearchParams({
      From: `whatsapp:${TWILIO_WHATSAPP_FROM}`,
      To: `whatsapp:${phone}`,
      Body:
        `Dear ${studentName ?? "Student"},\n\n` +
        `Your NSAT verification code is: *${code}*\n\n` +
        `This code is valid for 10 minutes.\n\n` +
        `— Noida International University`,
    });

    // FIXES Issue #36: Add timeout via AbortController
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 10_000); // 10s timeout

    try {
      const response = await fetch(twilioUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "Authorization": `Basic ${Buffer.from(
            `${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}`
          ).toString("base64")}`,
        },
        body: body.toString(),
        signal: controller.signal,
      });

      clearTimeout(timeout);
      const json = await response.json() as Record<string, unknown>;
      console.log("[sendWhatsAppOtp] Twilio response:", JSON.stringify(json));

      if (!response.ok) {
        throw new Error(`Twilio error ${json["code"]}: ${json["message"]}`);
      }

      console.log(
        `[sendWhatsAppOtp] WhatsApp OTP sent to ${phone} for ${applicationNo}, SID: ${json["sid"]}`
      );
      return { success: true };
    } catch (error) {
      clearTimeout(timeout);
      console.error("[sendWhatsAppOtp] Failed:", error);
      await channelRef.delete();
      if ((error as Error).name === "AbortError") {
        throw new HttpsError("deadline-exceeded", "WhatsApp service timed out. Please try again.");
      }
      throw new HttpsError("internal", "Failed to send WhatsApp verification code");
    }
  }
);
