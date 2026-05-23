import 'package:cloud_firestore/cloud_firestore.dart';

/// One document in the `results` collection. Written once by the student
/// app on submission. Document ID = auto-generated.
class ResultModel {
  final String applicationNo;
  final String studentName;
  final String course;
  final String testId;
  final int correctCount;
  final int wrongCount;
  final int skippedCount;
  final double netScore;
  final double maxScore;
  final DateTime? submittedAt;
  final Map<String, String> shortAnswerResponses;

  ResultModel({
    required this.applicationNo,
    required this.studentName,
    required this.course,
    required this.testId,
    required this.correctCount,
    required this.wrongCount,
    required this.skippedCount,
    required this.netScore,
    required this.maxScore,
    this.submittedAt,
    this.shortAnswerResponses = const {},
  });

  factory ResultModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawShort = data['shortAnswerResponses'];
    final Map<String, String> shortAnswers;
    if (rawShort is Map) {
      shortAnswers = rawShort.map((k, v) => MapEntry(k.toString(), v.toString()));
    } else {
      shortAnswers = {};
    }
    return ResultModel(
      applicationNo: data['application_no'] ?? '',
      studentName: data['studentName'] ?? '',
      course: data['course'] ?? '',
      testId: data['testId'] ?? '',
      correctCount: (data['correctCount'] ?? 0) as int,
      wrongCount: (data['wrongCount'] ?? 0) as int,
      skippedCount: (data['skippedCount'] ?? 0) as int,
      netScore: (data['netScore'] ?? 0.0).toDouble(),
      maxScore: (data['maxScore'] ?? 0.0).toDouble(),
      submittedAt: data['submittedAt'] is Timestamp
          ? (data['submittedAt'] as Timestamp).toDate()
          : null,
      shortAnswerResponses: shortAnswers,
    );
  }

  /// `submittedAt` is written as a server timestamp by ResultService,
  /// so it is intentionally not included here.
  Map<String, dynamic> toMap() => {
        'application_no': applicationNo,
        'studentName': studentName,
        'course': course,
        'testId': testId,
        'correctCount': correctCount,
        'wrongCount': wrongCount,
        'skippedCount': skippedCount,
        'netScore': netScore,
        'maxScore': maxScore,
        'shortAnswerResponses': shortAnswerResponses,
      };
}