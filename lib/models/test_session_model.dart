import 'package:flutter/material.dart';

class TestSessionModel {
  final String categoryName;
  final int totalQuestions;
  final int durationMinutes;
  int timeRemainingSeconds;
  Map<String, int> answers; // Map of questionId -> selectedOptionIndex
  bool isSubmitted;

  TestSessionModel({
    required this.categoryName,
    required this.totalQuestions,
    required this.durationMinutes,
  })  : timeRemainingSeconds = durationMinutes * 60,
        answers = {},
        isSubmitted = false;

  int get answeredCount => answers.length;
  int get unansweredCount => totalQuestions - answeredCount;
}
