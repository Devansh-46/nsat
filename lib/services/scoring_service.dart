import '../models/question_model.dart';
import '../models/test_model.dart';

/// The computed outcome of a test submission.
class ScoreResult {
  final int correctCount;
  final int wrongCount;
  final int skippedCount;
  final double netScore;
  final double maxScore;

  ScoreResult({
    required this.correctCount,
    required this.wrongCount,
    required this.skippedCount,
    required this.netScore,
    required this.maxScore,
  });
}

/// Calculates a test score.
///
/// SWAP POINT — this is the single place scoring lives.
/// Phase 1 (Spark, no Cloud Functions): `scoreSubmission` runs locally,
/// reading `correctAnswerIndex` off the questions.
///
/// Phase 2 (Blaze): replace ONLY the body of `scoreSubmission` with an
/// `https.callable` Cloud Function call that takes the answers and the
/// testId and returns a ScoreResult. The signature stays identical, so
/// TestProvider and every screen are untouched by the swap.
///
/// When QuestionService._stripAnswers is true, questions arrive with a
/// sentinel answer index of -1 — local scoring would then be wrong, which
/// is the intended forcing function: stripping answers and moving scoring
/// server-side must happen together.
class ScoringService {
  /// Scores a submission.
  ///
  /// [questions] — the questions as presented, in order.
  /// [answers]   — questionIndex -> selectedOptionIndex. Missing keys
  ///               are treated as skipped.
  /// [test]      — supplies marks per question and negative marking.
  ScoreResult scoreSubmission({
    required List<QuestionModel> questions,
    required Map<int, int> answers,
    required TestModel test,
  }) {
    int correct = 0;
    int wrong = 0;

    for (var i = 0; i < questions.length; i++) {
      final selected = answers[i];
      if (selected == null) continue; // skipped
      if (questions[i].correctAnswerIndex == selected) {
        correct++;
      } else {
        wrong++;
      }
    }

    final skipped = questions.length - correct - wrong;

    final correctMarks = correct * test.marksPerQuestion;
    final negativeMarks = wrong * test.effectiveNegativeMarks;
    final net = correctMarks - negativeMarks;
    final max = questions.length * test.marksPerQuestion;

    return ScoreResult(
      correctCount: correct,
      wrongCount: wrong,
      skippedCount: skipped,
      netScore: net,
      maxScore: max,
    );
  }
}