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
  Map<int, int> answers; // questionIndex -> selectedOptionIndex
  bool isSubmitted;
  DateTime? submittedAt;
  List<QuestionModel> questions;

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

  int get answeredCount => answers.length;
  int get unansweredCount => totalQuestions - answeredCount;

  int get correctCount {
    int count = 0;
    answers.forEach((questionIndex, selectedOption) {
      if (questionIndex < questions.length &&
          questions[questionIndex].correctAnswerIndex == selectedOption) {
        count++;
      }
    });
    return count;
  }

  int get wrongCount {
    int count = 0;
    answers.forEach((questionIndex, selectedOption) {
      if (questionIndex < questions.length &&
          questions[questionIndex].correctAnswerIndex != selectedOption) {
        count++;
      }
    });
    return count;
  }

  int get skippedCount => totalQuestions - answeredCount;

  double get correctMarks => correctCount * marksPerQuestion;
  double get negativeMarks => wrongCount * negativeMarksPerWrong;
  double get netScore => correctMarks - negativeMarks;
  double get maxScore => totalQuestions * marksPerQuestion;

  String get formattedNetScore => netScore.toStringAsFixed(2);
  String get formattedMaxScore => maxScore.toStringAsFixed(2);

  void selectAnswer(int questionIndex, int optionIndex) {
    answers[questionIndex] = optionIndex;
  }

  void clearAnswer(int questionIndex) {
    answers.remove(questionIndex);
  }

  // 0=unanswered, 1=answered, 2=visited, 3=current
  int getQuestionState(int questionIndex, int currentQuestionIndex) {
    if (questionIndex == currentQuestionIndex) return 3;
    if (answers.containsKey(questionIndex)) return 1;
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
