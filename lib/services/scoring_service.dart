import 'package:cloud_functions/cloud_functions.dart';
import '../models/question_model.dart';
import '../models/test_model.dart';
import 'app_logger.dart';

/// The computed outcome of a test submission.
class ScoreResult {
  final String? resultId;
  final int correctCount;
  final int wrongCount;
  final int skippedCount;
  final double netScore;
  final double maxScore;

  /// Whether this test is configured to show results to students.
  final bool showResults;

  ScoreResult({
    this.resultId,
    required this.correctCount,
    required this.wrongCount,
    required this.skippedCount,
    required this.netScore,
    required this.maxScore,
    this.showResults = true,
  });
}

/// Scores a test submission via the scoreSubmission Cloud Function.
///
/// The function reads questions server-side, scores against the answer
/// key, writes the result doc, and flips the attempt lock — all in one
/// call. The client never sees correctAnswerIndex.
class ScoringService {
  static const _tag = 'ScoringService';
  final _log = AppLogger.instance;

  /// Scores a submission server-side.
  ///
  /// [answers] — questionIndex -> answer (int for MCQ, String for short answer).
  Future<ScoreResult> scoreSubmission({
    required String applicationNo,
    required String studentName,
    required String testId,
    required Map<int, dynamic> answers,
    // These params kept for API compat but no longer used locally
    List<QuestionModel>? questions,
    TestModel? test,
  }) async {
    final reqId = AppLogger.generateRequestId();
    _log.info(_tag,
        'Submitting score for $applicationNo (test: $testId, answers: ${answers.length})',
        requestId: reqId, persist: true);

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'asia-south1')
          .httpsCallable('scoreSubmission');

      final stringAnswers = <String, dynamic>{};
      answers.forEach((k, v) => stringAnswers[k.toString()] = v);

      final result = await callable.call<Map<String, dynamic>>({
        'application_no': applicationNo,
        'student_name': studentName,
        'test_id': testId,
        'answers': stringAnswers,
      });

      final data = result.data;
      if (data == null) {
        throw Exception('scoreSubmission returned null data');
      }
      final scoreResult = ScoreResult(
        resultId: data['resultId'] as String?,
        correctCount: (data['correctCount'] ?? 0).toInt(),
        wrongCount: (data['wrongCount'] ?? 0).toInt(),
        skippedCount: (data['skippedCount'] ?? 0).toInt(),
        netScore: (data['netScore'] ?? 0).toDouble(),
        maxScore: (data['maxScore'] ?? 0).toDouble(),
        showResults: data['showResults'] == true,
      );

      _log.info(_tag,
          'Score result for $applicationNo: ${scoreResult.netScore}/${scoreResult.maxScore} '
          '(correct: ${scoreResult.correctCount}, wrong: ${scoreResult.wrongCount})',
          requestId: reqId, persist: true);

      return scoreResult;
    } on FirebaseFunctionsException catch (e) {
      _log.error(_tag, 'scoreSubmission Cloud Function error for $applicationNo: ${e.code} ${e.message}',
          error: e, requestId: reqId);
      rethrow;
    } catch (e, st) {
      _log.error(_tag, 'scoreSubmission failed for $applicationNo: $e',
          error: e, stackTrace: st, requestId: reqId);
      rethrow;
    }
  }
}
