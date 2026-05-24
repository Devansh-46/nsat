/// The applicant detail returned by NPF API 2 (lead lookup by lead_id).
///
/// This data is fetched LIVE at login — only for students whose fee is
/// approved — and held in memory for that session only. It is never
/// stored in Firestore.
class LeadDetailsModel {
  final String leadId;
  final String name;

  /// Canonical course KEY (e.g. "btech") — already mapped, ready to use
  /// as a join key against tests.course / questions.course.
  final String courseKey;

  final String email;
  final String mobile;

  LeadDetailsModel({
    required this.leadId,
    required this.name,
    required this.courseKey,
    required this.email,
    required this.mobile,
  });

  factory LeadDetailsModel.fromApiDetails(
    Map<String, dynamic> details, {
    required String courseKey,
  }) {
    return LeadDetailsModel(
      leadId: details['lead_id'] ?? '',
      name: details['name'] ?? '',
      courseKey: courseKey,
      email: details['email'] ?? '',
      mobile: details['mobile'] ?? '',
    );
  }

  /// The email shown masked for confirmation, e.g. "bh****@yopmail.com".
  ///
  /// FIXES Issue #14: The previous logic used `at <= 2` which left
  /// short emails like "ab@x.com" fully unmasked. Fixed to:
  /// - If the local part is 1 char, return as-is (can't mask further).
  /// - Always show at most 1 character before the mask.
  /// - Guarantee at least "*@domain" is shown.
  String get maskedEmail {
    final at = email.indexOf('@');
    // No @ found or malformed
    if (at < 0) return '****';
    // Local part is empty or single char — can't meaningfully mask
    if (at <= 1) return email;

    // Show only the first character, mask the rest of the local part
    final shown = email.substring(0, 1);
    final domain = email.substring(at);
    final maskLength = at - 1; // chars to mask
    return '$shown${'*' * maskLength}$domain';
  }
}
