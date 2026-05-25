// ─── Super Admin allowlist ─────────────────────────────────────────
// These emails get { admin: true, superAdmin: true } custom claims.
// They can manage other admins, view logs, and access everything.
// Set in functions/.env:
//   SUPERADMIN_EMAILS=superadmin1@niu.edu.in,superadmin2@niu.edu.in
export const SUPERADMIN_EMAILS = (process.env.SUPERADMIN_EMAILS ?? "")
  .split(",")
  .map((e) => e.trim())
  .filter((e) => e.length > 0);

// ─── Legacy admin allowlist (kept for backward compat) ─────────────
// If ADMIN_EMAILS is set, these are also treated as superadmins.
export const ALLOWED_ADMIN_EMAILS = (process.env.ADMIN_EMAILS ?? "")
  .split(",")
  .map((e) => e.trim())
  .filter((e) => e.length > 0);
