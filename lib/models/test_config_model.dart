class TestConfigModel {
  final String id;
  final String title;
  final String category;
  final int questionCount;
  final int durationMinutes;
  final double marksPerQuestion;
  final bool negativeMarking;
  final double negativeMarksPerWrong;
  final String startDate;
  final bool isPublished;

  TestConfigModel({
    required this.id,
    required this.title,
    required this.category,
    this.questionCount = 60,
    this.durationMinutes = 60,
    this.marksPerQuestion = 1.0,
    this.negativeMarking = true,
    this.negativeMarksPerWrong = 0.25,
    this.startDate = '',
    this.isPublished = false,
  });

  factory TestConfigModel.fromJson(Map<String, dynamic> json) {
    return TestConfigModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      questionCount: json['questionCount'] ?? 60,
      durationMinutes: json['durationMinutes'] ?? 60,
      marksPerQuestion: (json['marksPerQuestion'] ?? 1.0).toDouble(),
      negativeMarking: json['negativeMarking'] ?? true,
      negativeMarksPerWrong: (json['negativeMarksPerWrong'] ?? 0.25).toDouble(),
      startDate: json['startDate'] ?? '',
      isPublished: json['isPublished'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'questionCount': questionCount,
      'durationMinutes': durationMinutes,
      'marksPerQuestion': marksPerQuestion,
      'negativeMarking': negativeMarking,
      'negativeMarksPerWrong': negativeMarksPerWrong,
      'startDate': startDate,
      'isPublished': isPublished,
    };
  }
}
