// ─── Admin allowlist ───────────────────────────────────────────────
// Only emails in this list can be granted admin custom claims.
// Set in functions/.env:
//   ADMIN_EMAILS=admin1@niu.edu.in,admin2@niu.edu.in
export const ALLOWED_ADMIN_EMAILS = (process.env.ADMIN_EMAILS ?? "")
  .split(",")
  .map((e) => e.trim())
  .filter((e) => e.length > 0);


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

// ─── Twilio WhatsApp ───────────────────────────────────────────────
// Set in functions/.env:
//   TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
//   TWILIO_AUTH_TOKEN=your_auth_token_here
//   TWILIO_WHATSAPP_FROM=+14155238886   ← sandbox number (or prod number later)
export const TWILIO_ACCOUNT_SID  = process.env.TWILIO_ACCOUNT_SID  ?? "";
export const TWILIO_AUTH_TOKEN   = process.env.TWILIO_AUTH_TOKEN   ?? "";
export const TWILIO_WHATSAPP_FROM = process.env.TWILIO_WHATSAPP_FROM ?? "";

// ─── Course → School Paper mapping ─────────────────────────────────
// NPF returns specific course/program names. Question papers are per SCHOOL.
// Source: https://niu.edu.in/courses-fee-structure-for-2026-27/
//
// Paper keys (used in questions.course and tests.course):
//   soahs_ug   = School of Allied Health & Care Sciences (UG)
//   soahs_pg   = School of Allied Health & Care Sciences (PG)
//   son        = School of Nursing
//   set_ug     = School of Engineering & Technology (UG)
//   set_pg     = School of Engineering & Technology (PG)
//   sbm_ug     = School of Business Management (UG)
//   sbm_pg     = School of Business Management (PG)
//   solla_ug   = School of Law & Legal Affairs (UG - integrated 5yr)
//   solla_pg   = School of Law & Legal Affairs (PG - LLB 3yr, LLM)
//   sjmc       = School of Journalism & Mass Communication
//   sos_ug     = School of Sciences UG (includes BCA)
//   sos_pg     = School of Sciences PG (includes MCA, M.Sc)
//   sola       = School of Liberal Arts
//   sofad      = School of Fine Arts & Design (includes Architecture)
//   soe        = School of Education
//   sop        = School of Pharmacy

export const COURSE_KEY_MAP: Record<string, string> = {

  // ── SOAHS UG: School of Allied Health & Care Sciences (Undergraduate) ──
  "BPT": "soahs_ug",
  "B.Optom": "soahs_ug",
  "B. Optom": "soahs_ug",
  "BMLS": "soahs_ug",
  "BMLT": "soahs_ug",
  "BMRIT": "soahs_ug",
  "B.Sc-RIT": "soahs_ug",
  "BRIT": "soahs_ug",
  "B. AOTT": "soahs_ug",
  "B.Sc-OTT": "soahs_ug",
  "B.Sc (CCT)": "soahs_ug",
  "B.Sc CCT": "soahs_ug",
  "B.Sc- CCT": "soahs_ug",
  "BND": "soahs_ug",
  "B.Sc-N&D": "soahs_ug",
  "B.Sc (Cardiac Care Technology)": "soahs_ug",
  "BOT": "soahs_ug",
  "B.Sc- Opt": "soahs_ug",

  // ── SOAHS PG: School of Allied Health & Care Sciences (Postgraduate) ──
  "MPT": "soahs_pg",
  "MMLS": "soahs_pg",
  "MMLT": "soahs_pg",
  "MMRIT": "soahs_pg",
  "MPH": "soahs_pg",
  "PGDEMS": "soahs_pg",

  // ── SON: School of Nursing ──
  "GNM": "son",
  "B.Sc Nursing": "son",
  "B.Sc-N": "son",
  "B.Sc. Nursing": "son",
  "B.Sc (Nursing)": "son",
  "ANM": "son",

  // ── SET UG: School of Engineering & Technology (Undergraduate) ──
  "B.Tech": "set_ug",
  "B.Tech / Engineering": "set_ug",
  "B.Tech (CSE)": "set_ug",
  "B.Tech (AI & ML)": "set_ug",
  "B.Tech (Data Science)": "set_ug",
  "B.Tech (Cyber Security)": "set_ug",
  "B.Tech (Robotics)": "set_ug",
  "B.Tech (Biotechnology)": "set_ug",
  "B.Tech (ME)": "set_ug",
  "B.Tech (CE)": "set_ug",
  "B.Tech (EE)": "set_ug",
  "B.Tech (ECE)": "set_ug",
  "B.Tech (IT)": "set_ug",
  "B.Tech (Semiconductor)": "set_ug",
  "B.Tech (Mechatronics)": "set_ug",
  "B.Tech Lateral Entry": "set_ug",
  "Diploma (Electrical)": "set_ug",
  "Diploma (Mechanical)": "set_ug",
  "Diploma (Civil)": "set_ug",
  "Diploma (CSE)": "set_ug",

  // ── SET PG: School of Engineering & Technology (Postgraduate) ──
  "M.Tech": "set_pg",
  "M.Tech (CSE)": "set_pg",
  "M.Tech (ME)": "set_pg",
  "M.Tech (CE)": "set_pg",
  "M.Tech (Biotechnology)": "set_pg",
  "M.Tech (EE)": "set_pg",

  // ── SBM UG: School of Business Management (Undergraduate) ──
  "BBA": "sbm_ug",
  "BBA-HHM": "sbm_ug",
  "BBA-AV": "sbm_ug",
  "BBA (Hons)": "sbm_ug",
  "B.Com": "sbm_ug",
  "B. Com (Hons.)": "sbm_ug",
  "B.Com (Hons.)": "sbm_ug",
  "B.Com (Hons)": "sbm_ug",
  "BFSI": "sbm_ug",
  "Bachelor of Hospital & Health Management": "sbm_ug",
  "Bachelor of Business Administration": "sbm_ug",
  "Bachelor of Commerce": "sbm_ug",

  // ── SBM PG: School of Business Management (Postgraduate) ──
  "MBA": "sbm_pg",
  "MBA (Finance)": "sbm_pg",
  "MBA (Marketing)": "sbm_pg",
  "MBA (HR)": "sbm_pg",
  "MBA-HHM": "sbm_pg",
  "MBA-PM": "sbm_pg",
  "MBA-AGRI BUSINESS": "sbm_pg",
  "MBA DATA ANALYTICS-IBM": "sbm_pg",
  "MBA-ELITE": "sbm_pg",
  "MBA GLOBAL PROGRAMME": "sbm_pg",
  "MBA DUAL SPECIALIZATION": "sbm_pg",
  "PGDM": "sbm_pg",
  "M. Com": "sbm_pg",
  "M.Com": "sbm_pg",
  "Master of Business Administration": "sbm_pg",
  "Master of Commerce": "sbm_pg",

  // ── SOLLA UG: School of Law & Legal Affairs (5yr integrated) ──
  "BA LLB": "solla_ug",
  "BA LLB (Hons.)": "solla_ug",
  "BBA LLB": "solla_ug",
  "BBA LLB.": "solla_ug",
  "BBA LLB (Hons.)": "solla_ug",

  // ── SOLLA PG: School of Law & Legal Affairs (LLB 3yr / LLM) ──
  "LLB": "solla_pg",
  "LLM": "solla_pg",

  // ── SJMC: School of Journalism & Mass Communication ──
  "BA-JMC": "sjmc",
  "BA (Journalism & Mass Communication)": "sjmc",
  "MA-JMC": "sjmc",
  "MA (Journalism & Mass Communication)": "sjmc",

  // ── SOS UG: School of Sciences (Undergraduate) ──
  "B.Sc (Biotechnology)": "sos_ug",
  "B.Sc (Hons.) Biotechnology": "sos_ug",
  "B.Sc (Microbiology)": "sos_ug",
  "B.Sc (Hons.) Microbiology": "sos_ug",
  "B.Sc (Agriculture)": "sos_ug",
  "B.Sc (Hons.) Agriculture": "sos_ug",
  "B.Sc-AG": "sos_ug",
  "B.Sc (Forensic Science)": "sos_ug",
  "B.Sc (Hons.) Forensic Science": "sos_ug",
  "B.Sc (Physics)": "sos_ug",
  "B.Sc (Hons.) Physics (Instrumentation)": "sos_ug",
  "B.Sc (Industrial Chemistry)": "sos_ug",
  "B.Sc (Hons.) Industrial Chemistry": "sos_ug",
  "B.Sc (Mathematics)": "sos_ug",
  "B.Sc (Hons.) Mathematics": "sos_ug",
  "B.Sc (IT)": "sos_ug",
  "B.Sc (Hons.) Information Technology": "sos_ug",
  "B.Sc (CS)": "sos_ug",
  "B.Sc (Hons.) Computer Science": "sos_ug",
  "B.Sc": "sos_ug",
  "BCA": "sos_ug",
  "BCA (Hons.)": "sos_ug",
  "BCA (AI/ML)": "sos_ug",
  "BCA (Data Science)": "sos_ug",
  "BCA (Cyber Security)": "sos_ug",

  // ── SOS PG: School of Sciences (Postgraduate) ──
  "M.Sc": "sos_pg",
  "M.Sc (Biotechnology)": "sos_pg",
  "M.Sc (Microbiology)": "sos_pg",
  "M.Sc (Agriculture)": "sos_pg",
  "M.Sc (Forensic Science)": "sos_pg",
  "M.Sc (IT)": "sos_pg",
  "M.Sc (CS)": "sos_pg",
  "MCA": "sos_pg",

  // ── SOLA: School of Liberal Arts ──
  "BA (English)": "sola",
  "BA (Hons) English": "sola",
  "BA (Psychology)": "sola",
  "BA (Hons) Psychology": "sola",
  "BA (Sociology)": "sola",
  "BA (Hons) Sociology": "sola",
  "BA (Political Science)": "sola",
  "BA (Hons) Political Science": "sola",
  "BA (Public Administration)": "sola",
  "BA (Geography)": "sola",
  "BA (Hons) Geography": "sola",
  "BA (International Relations)": "sola",
  "BA (Hons) International Relation": "sola",
  "MA (English)": "sola",
  "MA (Psychology)": "sola",
  "MA (Geography)": "sola",
  "MA (International Relation)": "sola",

  // ── SOFAD: School of Fine Arts & Design (+ Architecture) ──
  //"BFA": "sofad",
  //"BFA (Animation & VFX)": "sofad",
  //"BID": "sofad",
  //"B.Des": "sofad",
  //"B.Des.": "sofad",
  //"B.Interior": "sofad",
  //"MFA": "sofad",

  // ── SOE: School of Education ──
  "B.Ed": "soe",
  "B.Ed.": "soe",
  "MA (Education)": "soe",
  "MA Education": "soe",

  // ── SOP: School of Pharmacy ──
  "B.Pharm": "sop",
  "B. Pharm": "sop",
  "B.Pharm.": "sop",
  "B.Pharma": "sop",
  "B. Pharm. (Lateral Entry)": "sop",
  "D.Pharm": "sop",
  "D. Pharm": "sop",
  "D.Pharm.": "sop",
  "D.Pharma": "sop",
  "M.Pharm": "sop",
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