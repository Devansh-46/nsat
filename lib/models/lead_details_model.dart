/// The applicant detail returned by NPF API 2 (lead lookup by lead_id).
///
/// This data is fetched LIVE at login — only for students whose fee is
/// approved — and held in memory for that session only. It is never
/// stored in Firestore.
///
/// Mirrors the API 2 response `data.details` object:
///   { name, mobile, lead_stage, email, course, lead_id }
///
/// NOTE: `course` from NPF is a DISPLAY string (e.g. "BBA",
/// "B.Tech / Engineering"). Before it is used as a Firestore join key it
/// must be mapped to the canonical key (e.g. "btech") — the same map as
/// seed_firestore.py's COURSE_KEY_MAP. The mapping is done by whatever
/// produces this model (the Cloud Function in Phase 2; the dev stub on
/// Spark), so `courseKey` here is already canonical.
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

  /// Builds the model from the raw NPF API 2 `data.details` map.
  ///
  /// [courseKey] is passed in already-mapped, because the raw response
  /// holds the display name, not the key.
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
  String get maskedEmail {
    final at = email.indexOf('@');
    if (at <= 2) return email;
    return '${email.substring(0, 2)}****${email.substring(at)}';
  }
}