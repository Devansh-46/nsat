import 'question_model.dart';

class TestSessionModel {
  final String studentId;
  final String studentName;
  final String categoryName;
  final int totalQuestions;
  final int durationMinutes;
  final double marksPerQuestion;
  final double negativeMarksPerWrong;
  int timeRemainingSeconds;

  /// Answers map: questionIndex -> answer value.
  /// For MCQ: int (option index). For short answer: String.
  Map<int, dynamic> answers;

  bool isSubmitted;
  DateTime? submittedAt;
  List<QuestionModel> questions;

  /// Server-authoritative score overrides.
  int? _serverCorrect;
  int? _serverWrong;
  int? _serverSkipped;
  double? _serverNetScore;
  double? _serverMaxScore;

  TestSessionModel({
    required this.studentId,
    required this.studentName,
    required this.categoryName,
    required this.totalQuestions,
    required this.durationMinutes,
    this.marksPerQuestion = 1.0,
    this.negativeMarksPerWrong = 0.25,
    List<QuestionModel>? questions,
  })  : timeRemainingSeconds = durationMinutes * 60,
        answers = {},
        isSubmitted = false,
        questions = questions ?? [];

  void setServerScores({
    required int correctCount,
    required int wrongCount,
    required int skippedCount,
    required double netScore,
    required double maxScore,
  }) {
    _serverCorrect = correctCount;
    _serverWrong = wrongCount;
    _serverSkipped = skippedCount;
    _serverNetScore = netScore;
    _serverMaxScore = maxScore;
  }

  int get answeredCount {
    int count = 0;
    for (final entry in answers.entries) {
      final val = entry.value;
      if (val is int) {
        count++;
      } else if (val is String && val.trim().isNotEmpty) {
        count++;
      }
    }
    return count;
  }

  int get unansweredCount => totalQuestions - answeredCount;

  int get correctCount {
    if (_serverCorrect != null) return _serverCorrect!;
    int count = 0;
    answers.forEach((questionIndex, answer) {
      if (questionIndex >= questions.length) return;
      final q = questions[questionIndex];
      if (q.isShortAnswer) return;
      if (q.isMultipleChoice && answer is int) {
        if (q.correctAnswerIndex == answer) count++;
      }
    });
    return count;
  }

  int get wrongCount {
    if (_serverWrong != null) return _serverWrong!;
    int count = 0;
    answers.forEach((questionIndex, answer) {
      if (questionIndex >= questions.length) return;
      final q = questions[questionIndex];
      if (q.isShortAnswer) return;
      if (q.isMultipleChoice && answer is int) {
        if (q.correctAnswerIndex != answer) count++;
      }
    });
    return count;
  }

  /// Number of graded questions (MCQs only).
  int get gradedQuestionCount =>
      questions.where((q) => q.isMultipleChoice).length;

  /// FIXES Issue #17: skippedCount is clamped to [0, gradedQuestionCount]
  /// to prevent negative values when short-answer questions affect the count.
  int get skippedCount {
    if (_serverSkipped != null) return _serverSkipped!;
    return (gradedQuestionCount - correctCount - wrongCount)
        .clamp(0, gradedQuestionCount);
  }

  double get correctMarks => correctCount * marksPerQuestion;
  double get negativeMarks => wrongCount * negativeMarksPerWrong;
  double get netScore => _serverNetScore ?? (correctMarks - negativeMarks);
  double get maxScore => _serverMaxScore ?? (gradedQuestionCount * marksPerQuestion);

  String get formattedNetScore => netScore.toStringAsFixed(2);
  String get formattedMaxScore => maxScore.toStringAsFixed(2);

  void selectAnswer(int questionIndex, dynamic answer) {
    answers[questionIndex] = answer;
  }

  void clearAnswer(int questionIndex) {
    answers.remove(questionIndex);
  }

  int getQuestionState(int questionIndex, int currentQuestionIndex) {
    if (questionIndex == currentQuestionIndex) return 3;
    if (answers.containsKey(questionIndex)) {
      final val = answers[questionIndex];
      if (val is int) return 1;
      if (val is String && val.trim().isNotEmpty) return 1;
    }
    return 0;
  }

  void submit() {
    isSubmitted = true;
    submittedAt = DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'categoryName': categoryName,
      'totalQuestions': totalQuestions,
      'durationMinutes': durationMinutes,
      'marksPerQuestion': marksPerQuestion,
      'negativeMarksPerWrong': negativeMarksPerWrong,
      'correctCount': correctCount,
      'wrongCount': wrongCount,
      'skippedCount': skippedCount,
      'netScore': netScore,
      'maxScore': maxScore,
      'submittedAt': submittedAt?.toIso8601String(),
    };
  }

  factory TestSessionModel.fromJson(Map<String, dynamic> json) {
    final session = TestSessionModel(
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      categoryName: json['categoryName'] ?? '',
      totalQuestions: json['totalQuestions'] ?? 0,
      durationMinutes: json['durationMinutes'] ?? 0,
      marksPerQuestion: (json['marksPerQuestion'] ?? 1.0).toDouble(),
      negativeMarksPerWrong: (json['negativeMarksPerWrong'] ?? 0.25).toDouble(),
    );
    session.isSubmitted = true;
    session.submittedAt = json['submittedAt'] != null
        ? DateTime.tryParse(json['submittedAt'])
        : null;
    return session;
  }
}
