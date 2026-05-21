import 'package:cloud_firestore/cloud_firestore.dart';

/// The type of question — MCQ (select an option) or short answer (type text).
enum QuestionType { multipleChoice, shortAnswer }

/// Represents one document in the `questions` Firestore collection.
///
/// Supports both MCQ and short-answer question types. For backward
/// compatibility, `type` defaults to `multipleChoice` if absent in
/// Firestore, and `options`/`correctAnswerIndex` remain available for MCQs.
class QuestionModel {
  final String id;
  final String text;

  /// The question type. Defaults to MCQ for backward compat.
  final QuestionType type;

  /// Options for MCQ. Empty for short-answer questions.
  final List<String> options;

  /// Correct option index for MCQ (0–3). -1 when stripped or short-answer.
  final int correctAnswerIndex;

  /// Correct text answer(s) for short-answer questions.
  /// For NSAT, short answers are ungraded descriptive responses
  /// (e.g. "Why do you want to join NIU?") — this field is unused.
  final List<String> correctAnswerTexts;

  /// Minimum word count hint for short-answer questions.
  final int minWords;

  /// Maximum word count hint for short-answer questions.
  final int maxWords;

  /// Course key (e.g. "btech"). Named `category` internally for legacy
  /// compatibility with TestSessionModel; maps to Firestore `course`.
  final String category;

  /// Optional topic tag.
  final String topic;

  QuestionModel({
    required this.id,
    required this.text,
    this.type = QuestionType.multipleChoice,
    this.options = const [],
    this.correctAnswerIndex = -1,
    this.correctAnswerTexts = const [],
    this.minWords = 0,
    this.maxWords = 0,
    this.category = '',
    this.topic = '',
  });

  /// Whether this is a short-answer question.
  bool get isShortAnswer => type == QuestionType.shortAnswer;

  /// Whether this is a multiple-choice question.
  bool get isMultipleChoice => type == QuestionType.multipleChoice;

  /// Builds from a Firestore document.
  factory QuestionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return QuestionModel.fromMap(data, id: doc.id);
  }

  /// Builds from a plain map (used by QuestionService and seed scripts).
  factory QuestionModel.fromMap(Map<String, dynamic> data, {String id = ''}) {
    final rawType = data['type'] as String?;
    final type = rawType == 'shortAnswer'
        ? QuestionType.shortAnswer
        : QuestionType.multipleChoice;

    // correctAnswerTexts can be a single string or a list
    final rawTexts = data['correctAnswerTexts'];
    List<String> correctTexts = [];
    if (rawTexts is List) {
      correctTexts = rawTexts.map((e) => e.toString()).toList();
    } else if (rawTexts is String && rawTexts.isNotEmpty) {
      correctTexts = [rawTexts];
    }

    return QuestionModel(
      id: id,
      text: data['text'] ?? '',
      type: type,
      options: List<String>.from(data['options'] ?? const []),
      correctAnswerIndex: (data['correctAnswerIndex'] ?? -1) as int,
      correctAnswerTexts: correctTexts,
      minWords: (data['minWords'] ?? 0) as int,
      maxWords: (data['maxWords'] ?? 0) as int,
      category: data['course'] ?? data['category'] ?? '',
      topic: data['topic'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'type': type == QuestionType.shortAnswer ? 'shortAnswer' : 'multipleChoice',
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'correctAnswerTexts': correctAnswerTexts,
      'minWords': minWords,
      'maxWords': maxWords,
      'course': category,
      'topic': topic,
    };
  }

  /// Legacy fromJson for backward compat.
  factory QuestionModel.fromJson(Map<String, dynamic> json) =>
      QuestionModel.fromMap(json, id: json['id'] ?? '');

  Map<String, dynamic> toJson() => {'id': id, ...toMap()};
}