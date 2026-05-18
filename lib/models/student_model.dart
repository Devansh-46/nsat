import 'package:cloud_firestore/cloud_firestore.dart';

/// One document in the `students` Firestore collection.
///
/// A local copy of NoPaperForms (NPF) data, synced from NPF API 1
/// (`application/v1/list`) every 30 minutes by a Cloud Function.
/// The app only ever READS this collection.
///
/// API 1 returns ONLY these fields — name, course, email and phone are
/// NOT here. Those come from a live NPF API 2 call at login (see
/// LeadDetailsModel), and are never stored in Firestore.
///
/// Document ID = the NIU ID (application number).
class StudentModel {
  final String applicationNo;
  final String paymentStatus;
  final String leadId;
  final DateTime? lastSyncedAt;

  StudentModel({
    required this.applicationNo,
    required this.paymentStatus,
    required this.leadId,
    this.lastSyncedAt,
  });

  /// True only when NPF has approved the application fee.
  /// The single check the fee gate relies on.
  bool get isFeeApproved => paymentStatus == 'Payment Approved';

  factory StudentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return StudentModel(
      applicationNo: data['application_no'] ?? doc.id,
      paymentStatus: data['payment_status'] ?? 'Payment Pending',
      leadId: data['lead_id'] ?? '',
      lastSyncedAt: data['lastSyncedAt'] is Timestamp
          ? (data['lastSyncedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'application_no': applicationNo,
        'payment_status': paymentStatus,
        'lead_id': leadId,
        'lastSyncedAt':
            lastSyncedAt != null ? Timestamp.fromDate(lastSyncedAt!) : null,
      };
}