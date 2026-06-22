/// Granular per-feature admin permission catalog.
///
/// Single source of truth on the client — mirrors the `PERMISSION_KEYS`
/// list in functions/src/adminClaims.ts exactly. Map is key → human label.
///
/// Managing admins is NOT a grantable permission — it remains superadmin-only.
const Map<String, String> kAdminPermissions = {
  'manage_tests': 'Create / edit tests',
  'manage_questions': 'Add / edit questions',
  'import_questions': 'Import questions (CSV)',
  'grade_short_answers': 'Grade short answers',
  'view_results': 'View results',
  'export_results': 'Export results (CSV)',
  'send_notifications': 'Send notifications',
  'view_logs': 'View activity logs',
  'manage_course_access': 'Manage course access',
};
