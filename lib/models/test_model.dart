import 'package:cloud_firestore/cloud_firestore.dart';

class TestModel {
  final String id;
  final String title;
  final String course;
  final int questionCount;
  final int durationMinutes;
  final double marksPerQuestion;
  final bool negativeMarking;
  final double negativeMarksPerWrong;
  final bool isPublished;

  TestModel({
    required this.id,
    required this.title,
    required this.course,
    required this.questionCount,
    required this.durationMinutes,
    required this.marksPerQuestion,
    required this.negativeMarking,
    required this.negativeMarksPerWrong,
    required this.isPublished,
  });

  double get effectiveNegativeMarks =>
      negativeMarking ? negativeMarksPerWrong : 0.0;

  factory TestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TestModel(
      id: doc.id,
      title: data['title'] ?? '',
      course: data['course'] ?? '',
      questionCount: (data['questionCount'] ?? 0) as int,
      durationMinutes: (data['durationMinutes'] ?? 0) as int,
      marksPerQuestion: (data['marksPerQuestion'] ?? 1.0).toDouble(),
      negativeMarking: data['negativeMarking'] ?? false,
      negativeMarksPerWrong: (data['negativeMarksPerWrong'] ?? 0.0).toDouble(),
      isPublished: data['isPublished'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'course': course,
        'questionCount': questionCount,
        'durationMinutes': durationMinutes,
        'marksPerQuestion': marksPerQuestion,
        'negativeMarking': negativeMarking,
        'negativeMarksPerWrong': negativeMarksPerWrong,
        'isPublished': isPublished,
      };
}