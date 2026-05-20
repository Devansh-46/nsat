import 'package:cloud_functions/cloud_functions.dart';
import '../models/question_model.dart';
import '../models/test_model.dart';

/// The computed outcome of a test submission.
class ScoreResult {
  final String? resultId;
  final int correctCount;
  final int wrongCount;
  final int skippedCount;
  final double netScore;
  final double maxScore;

  ScoreResult({
    this.resultId,
    required this.correctCount,
    required this.wrongCount,
    required this.skippedCount,
    required this.netScore,
    required this.maxScore,
  });
}

/// Scores a test submission via the scoreSubmission Cloud Function.
///
/// The function reads questions server-side, scores against the answer
/// key, writes the result doc, and flips the attempt lock — all in one
/// call. The client never sees correctAnswerIndex.
class ScoringService {
  /// Scores a submission server-side.
  ///
  /// [applicationNo] — the student's NIU ID.
  /// [studentName] — confirmed name from LeadDetailsModel.
  /// [testId] — Firestore doc ID of the test.
  /// [answers] — questionIndex -> selectedOptionIndex.
  Future<ScoreResult> scoreSubmission({
    required String applicationNo,
    required String studentName,
    required String testId,
    required Map<int, int> answers,
    // These params kept for API compat but no longer used locally
    List<QuestionModel>? questions,
    TestModel? test,
  }) async {
    final callable = FirebaseFunctions.instanceFor(region: 'asia-south1')
        .httpsCallable('scoreSubmission');

    // Convert int keys to string keys for JSON
    final stringAnswers = <String, int>{};
    answers.forEach((k, v) => stringAnswers[k.toString()] = v);

    final result = await callable.call<Map<String, dynamic>>({
      'application_no': applicationNo,
      'student_name': studentName,
      'test_id': testId,
      'answers': stringAnswers,
    });

    final data = result.data;
    return ScoreResult(
      resultId: data['resultId'] as String?,
      correctCount: (data['correctCount'] ?? 0) as int,
      wrongCount: (data['wrongCount'] ?? 0) as int,
      skippedCount: (data['skippedCount'] ?? 0) as int,
      netScore: (data['netScore'] ?? 0.0).toDouble(),
      maxScore: (data['maxScore'] ?? 0.0).toDouble(),
    );
  }
}