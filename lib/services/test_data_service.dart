import '../models/question_model.dart';

class TestDataService {
  Future<List<QuestionModel>> fetchQuestionsForCategory(String categoryId) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network fetch
    
    // Generate 50 mock questions
    return List.generate(50, (index) {
      return QuestionModel(
        id: 'q_$index',
        text: 'This is a sample question ${index + 1} for $categoryId. What is the correct answer?',
        options: [
          'Option A for question ${index + 1}',
          'Option B for question ${index + 1}',
          'Option C for question ${index + 1}',
          'Option D for question ${index + 1}',
        ],
        correctAnswerIndex: index % 4, // Pseudo-random actual answer
      );
    });
  }
}
