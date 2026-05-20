// ─── NPF API credentials ───────────────────────────────────────────
// NPF uses access-key + secret-key passed as query params or headers.
// Set in functions/.env:
//   NPF_ACCESS_KEY=your_access_key
//   NPF_SECRET_KEY=your_secret_key
//   NPF_BASE_URL=https://api.nopaperforms.com

export const NPF_ACCESS_KEY = process.env.NPF_ACCESS_KEY ?? "";
export const NPF_SECRET_KEY = process.env.NPF_SECRET_KEY ?? "";
export const NPF_BASE_URL =
  process.env.NPF_BASE_URL ?? "https://api.nopaperforms.com";

// ─── SMTP for OTP emails ───────────────────────────────────────────
export const SMTP_HOST = process.env.SMTP_HOST ?? "smtp.gmail.com";
export const SMTP_PORT = parseInt(process.env.SMTP_PORT ?? "587", 10);
export const SMTP_USER = process.env.SMTP_USER ?? "";
export const SMTP_PASS = process.env.SMTP_PASS ?? "";
export const OTP_FROM_NAME = process.env.OTP_FROM_NAME ?? "NSAT NIU";

// ─── Course key map ────────────────────────────────────────────────
// NPF returns display strings; Firestore needs canonical keys.
// MUST match seed_firestore.py's COURSE_KEY_MAP exactly.
export const COURSE_KEY_MAP: Record<string, string> = {
  "B.Tech": "btech",
  "B.Tech / Engineering": "btech",
  "BBA": "bba",
  "MBA": "mba",
  "BCA": "bca",
  "MCA": "mca",
  "B.Sc": "bsc",
  "M.Sc": "msc",
  "LLB": "llb",
  "LLM": "llm",
  "B.Pharm": "bpharm",
  "M.Pharm": "mpharm",
  "B.Ed": "bed",
};

export function mapCourseKey(npfCourse: string): string {
  // Try exact match first, then trimmed, then case-insensitive
  if (COURSE_KEY_MAP[npfCourse]) return COURSE_KEY_MAP[npfCourse];
  const trimmed = npfCourse.trim();
  if (COURSE_KEY_MAP[trimmed]) return COURSE_KEY_MAP[trimmed];
  // Fallback: lowercase, strip spaces
  const lower = trimmed.toLowerCase().replace(/[\s\/]+/g, "");
  for (const [key, val] of Object.entries(COURSE_KEY_MAP)) {
    if (key.toLowerCase().replace(/[\s\/]+/g, "") === lower) return val;
  }
  // Unknown course — return lowercase slug so it doesn't silently break
  return trimmed.toLowerCase().replace(/[\s\/]+/g, "_");
}