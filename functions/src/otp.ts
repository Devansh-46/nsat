import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as crypto from "crypto";
import * as nodemailer from "nodemailer";
import {
  SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, OTP_FROM_NAME,
  MSG91_AUTHKEY, MSG91_INTEGRATED_NUM, MSG91_WA_TEMPLATE, MSG91_WA_LANG, MSG91_WA_NAMESPACE,
  MSG91_SMS_TEMPLATE_ID,
  REVIEW_BYPASS_ID, REVIEW_BYPASS_CODE
} from "./config";

// OTP validity: 10 minutes
const OTP_EXPIRY_MS = 10 * 60 * 1000;

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

export const sendOtp = onCall(
  { region: "asia-south1", consumeAppCheckToken: true },
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

    // ── Google Play review bypass ──
    // REMOVE BEFORE June 14 exam
    if (REVIEW_BYPASS_ID && applicationNo === REVIEW_BYPASS_ID) {
      const channelRef = getChannelRef(db, applicationNo, "email");
      const hashed = hashOtp(REVIEW_BYPASS_CODE);
      await channelRef.set({
        hashedCode: hashed,
        expiresAt: Date.now() + OTP_EXPIRY_MS,
        attempts: 0,
        channel: "email",
        createdAtMs: Date.now(),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`[REVIEW BYPASS] Email OTP set for ${applicationNo}, code: ${REVIEW_BYPASS_CODE}`);
      return { success: true };
    }

    const channelRef = getChannelRef(db, applicationNo, "email");

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

    await channelRef.set({
      hashedCode: hashed,
      expiresAt,
      attempts: 0,
      channel: "email",
      createdAtMs: Date.now(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

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

export const verifyOtp = onCall(
  { region: "asia-south1", consumeAppCheckToken: true },
  async (request) => {
    const db = admin.firestore();
    const applicationNo = request.data?.application_no as string | undefined;
    const code = request.data?.code as string | undefined;
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

    if (attempts >= 5) {
      await channelRef.delete();
      throw new HttpsError(
        "resource-exhausted",
        "Too many attempts — request a new code"
      );
    }

    if (Date.now() > (data.expiresAt as number)) {
      await channelRef.delete();
      throw new HttpsError(
        "deadline-exceeded",
        "Code has expired — request a new one"
      );
    }

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

    await channelRef.delete();
    console.log(`OTP verified for ${applicationNo} (channel: ${channel})`);
    return { verified: true };
  }
);

export const sendWhatsAppOtp = onCall(
  { region: "asia-south1", consumeAppCheckToken: true },
  async (request) => {
    const db = admin.firestore();
    const applicationNo = request.data?.application_no as string | undefined;
    const rawPhone = request.data?.phone as string | undefined;

    if (!applicationNo || !rawPhone) {
      throw new HttpsError("invalid-argument", "application_no and phone are required");
    }

    // ── Google Play review bypass ──
    // REMOVE BEFORE June 14 exam
    if (REVIEW_BYPASS_ID && applicationNo === REVIEW_BYPASS_ID) {
      const channelRef = getChannelRef(db, applicationNo, "whatsapp");
      const hashed = hashOtp(REVIEW_BYPASS_CODE);
      await channelRef.set({
        hashedCode: hashed,
        expiresAt: Date.now() + OTP_EXPIRY_MS,
        attempts: 0,
        channel: "whatsapp",
        phone: rawPhone,
        createdAtMs: Date.now(),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`[REVIEW BYPASS] WhatsApp OTP set for ${applicationNo}, code: ${REVIEW_BYPASS_CODE}`);
      return { success: true };
    }

    if (!MSG91_AUTHKEY || !MSG91_INTEGRATED_NUM || !MSG91_WA_TEMPLATE) {
      console.error("[sendWhatsAppOtp] MSG91 env vars not set");
      throw new HttpsError("failed-precondition", "WhatsApp service is not configured");
    }

    // MSG91 requires country code with no leading '+' (e.g. "919560877237")
    let phoneForMsg91 = rawPhone.trim().replace(/^\+/, "");
    if (/^\d{10}$/.test(phoneForMsg91)) {
      phoneForMsg91 = "91" + phoneForMsg91;
    }

    const channelRef = getChannelRef(db, applicationNo, "whatsapp");

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

    await channelRef.set({
      hashedCode: hashed,
      expiresAt,
      attempts: 0,
      channel: "whatsapp",
      phone: phoneForMsg91,
      createdAtMs: Date.now(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 10_000);

    try {
      const waUrl = "https://api.msg91.com/api/v5/whatsapp/whatsapp-outbound-message/bulk/";
      const waBody = {
        integrated_number: MSG91_INTEGRATED_NUM,
        content_type: "template",
        payload: {
          messaging_product: "whatsapp",
          type: "template",
          template: {
            name: MSG91_WA_TEMPLATE,
            language: { code: MSG91_WA_LANG, policy: "deterministic" },
            namespace: MSG91_WA_NAMESPACE,
            to_and_components: [
              {
                to: [phoneForMsg91],
                components: {
                  body_1:   { type: "text", value: code },
                  button_1: { subtype: "url", type: "text", value: code },
                },
              },
            ],
          },
        },
      };

      const response = await fetch(waUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json", authkey: MSG91_AUTHKEY },
        body: JSON.stringify(waBody),
        signal: controller.signal as unknown as AbortSignal,
      });

      clearTimeout(timeout);
      const json = await response.json() as Record<string, unknown>;
      console.log("[sendWhatsAppOtp] MSG91 response:", JSON.stringify(json));

      if (!response.ok || json["type"] === "error") {
        throw new Error(`MSG91 error: ${JSON.stringify(json)}`);
      }

      console.log(
        `[sendWhatsAppOtp] WhatsApp OTP sent to ${phoneForMsg91} for ${applicationNo}`
      );
      return { success: true };
    } catch (error) {
      clearTimeout(timeout);
      console.error("[sendWhatsAppOtp] Failed:", error);
      if ((error as Error).name === "AbortError") {
        throw new HttpsError("deadline-exceeded", "WhatsApp service timed out. Please try again.");
      }
      throw new HttpsError("internal", "Failed to send WhatsApp verification code");
    }
  }
);

// ─── SMS resend: user taps "Didn't receive? Resend via SMS" ────────
export const resendOtpViaSms = onCall(
  { region: "asia-south1", consumeAppCheckToken: true },
  async (request) => {
    const db = admin.firestore();
    const applicationNo = request.data?.application_no as string | undefined;
    const rawPhone = request.data?.phone as string | undefined;

    if (!applicationNo || !rawPhone) {
      throw new HttpsError("invalid-argument", "application_no and phone are required");
    }

    if (!MSG91_SMS_TEMPLATE_ID) {
      console.error("[resendOtpViaSms] MSG91_SMS_TEMPLATE_ID not set");
      throw new HttpsError("failed-precondition", "SMS service is not configured yet");
    }
    if (!MSG91_AUTHKEY) {
      console.error("[resendOtpViaSms] MSG91_AUTHKEY not set");
      throw new HttpsError("failed-precondition", "SMS service is not configured");
    }

    // Phone format: country code, no leading '+'
    let phoneForMsg91 = rawPhone.trim().replace(/^\+/, "");
    if (/^\d{10}$/.test(phoneForMsg91)) {
      phoneForMsg91 = "91" + phoneForMsg91;
    }

    const channelRef = getChannelRef(db, applicationNo, "whatsapp");

    // A WhatsApp OTP must have been sent first
    const existing = await channelRef.get();
    if (!existing.exists) {
      throw new HttpsError(
        "failed-precondition",
        "No WhatsApp OTP found — please request a WhatsApp code first."
      );
    }

    const data = existing.data()!;
    const createdAt = data.createdAtMs as number | undefined;

    // Minimum 15s since WhatsApp send to prevent abuse
    if (createdAt && Date.now() - createdAt < 15_000) {
      const secondsLeft = Math.ceil((15_000 - (Date.now() - createdAt)) / 1000);
      throw new HttpsError(
        "resource-exhausted",
        `Please wait ${secondsLeft} seconds before requesting SMS.`
      );
    }

    // Check if SMS was already sent for this OTP (prevent spam)
    if (data.smsResentAt) {
      const smsResentAt = data.smsResentAt as number;
      if (Date.now() - smsResentAt < 60_000) {
        const secondsLeft = Math.ceil((60_000 - (Date.now() - smsResentAt)) / 1000);
        throw new HttpsError(
          "resource-exhausted",
          `SMS already sent. Please wait ${secondsLeft} seconds before requesting again.`
        );
      }
    }

    // Generate a fresh OTP (can't recover the hashed one)
    const code = generateOtp();
    const hashed = hashOtp(code);

    // Overwrite the Firestore doc — same "whatsapp" channel key so verifyOtp still works
    await channelRef.update({
      hashedCode: hashed,
      expiresAt: Date.now() + OTP_EXPIRY_MS,
      attempts: 0,
      smsResentAt: Date.now(),
    });

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 10_000);

    try {
      const smsUrl = "https://api.msg91.com/api/v5/flow/";
      const smsBody = {
        template_id: MSG91_SMS_TEMPLATE_ID,
        recipients: [
          {
            mobiles: phoneForMsg91,
            otp: code,
          },
        ],
      };

      const response = await fetch(smsUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json", authkey: MSG91_AUTHKEY },
        body: JSON.stringify(smsBody),
        signal: controller.signal as unknown as AbortSignal,
      });

      clearTimeout(timeout);
      const json = await response.json() as Record<string, unknown>;
      console.log("[resendOtpViaSms] MSG91 SMS response:", JSON.stringify(json));

      if (!response.ok || json["type"] === "error") {
        throw new Error(`MSG91 SMS error: ${JSON.stringify(json)}`);
      }

      console.log(
        `[resendOtpViaSms] SMS OTP sent to ${phoneForMsg91} for ${applicationNo}`
      );
      return { success: true };
    } catch (error) {
      clearTimeout(timeout);
      console.error("[resendOtpViaSms] Failed:", error);
      if ((error as Error).name === "AbortError") {
        throw new HttpsError("deadline-exceeded", "SMS service timed out. Please try again.");
      }
      throw new HttpsError("internal", "Failed to send SMS verification code");
    }
  }
);