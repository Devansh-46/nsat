import 'package:cloud_firestore/cloud_firestore.dart';

/// Lifecycle state of a student's single attempt. The crash-safe
/// extension to DATA_MODEL.md: a started-but-unfinished attempt (app
/// crash on flaky kiosk wifi) is distinguishable from a finished one.
enum AttemptStatus { inProgress, completed }

/// One document in the `attempts` collection — the one-attempt lock.
/// Document ID = application_no. Never touched by the NPF sync.
class AttemptModel {
  final String applicationNo;
  final AttemptStatus status;
  final String testId;
  final DateTime? attemptedAt;

  AttemptModel({
    required this.applicationNo,
    required this.status,
    required this.testId,
    this.attemptedAt,
  });

  /// The real "locked" check — finished, not merely started.
  bool get isCompleted => status == AttemptStatus.completed;
  bool get isInProgress => status == AttemptStatus.inProgress;

  static AttemptStatus _statusFromString(String? raw) {
    switch (raw) {
      case 'completed':
        return AttemptStatus.completed;
      case 'in_progress':
      default:
        return AttemptStatus.inProgress;
    }
  }

  static String statusToString(AttemptStatus status) {
    switch (status) {
      case AttemptStatus.completed:
        return 'completed';
      case AttemptStatus.inProgress:
        return 'in_progress';
    }
  }

  factory AttemptModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AttemptModel(
      applicationNo: doc.id,
      status: _statusFromString(data['status'] as String?),
      testId: data['testId'] ?? '',
      attemptedAt: data['attemptedAt'] is Timestamp
          ? (data['attemptedAt'] as Timestamp).toDate()
          : null,
    );
  }
}