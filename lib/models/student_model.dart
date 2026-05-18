import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents one document in the `students` Firestore collection.
///
/// This collection is a local copy of NoPaperForms (NPF) applicant data,
/// refreshed by the NPF sync Cloud Function. The app only ever READS this
/// collection — it never writes to it.
///
/// Document ID = the NIU ID (application number).
class StudentModel {
  /// NIU ID — the student's application number. Same as the document ID.
  final String applicationNo;

  /// Payment status from NPF. Expected values: "Payment Approved"
  /// or "Payment Pending". Only "Payment Approved" passes the fee gate.
  final String paymentStatus;

  /// NPF lead identifier. Used later to fetch the registered email
  /// via a live NPF call (the email is not stored in this collection).
  final String leadId;

  /// When this record was last refreshed from NPF. May be null if a
  /// document was created manually for testing.
  final DateTime? lastSyncedAt;

  StudentModel({
    required this.applicationNo,
    required this.paymentStatus,
    required this.leadId,
    this.lastSyncedAt,
  });

  /// True only when NPF has approved the application fee.
  /// This is the single check the fee gate relies on.
  bool get isFeeApproved => paymentStatus == 'Payment Approved';

  /// Builds a StudentModel from a Firestore document.
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

  Map<String, dynamic> toMap() {
    return {
      'application_no': applicationNo,
      'payment_status': paymentStatus,
      'lead_id': leadId,
      'lastSyncedAt': lastSyncedAt != null
          ? Timestamp.fromDate(lastSyncedAt!)
          : null,
    };
  }
}