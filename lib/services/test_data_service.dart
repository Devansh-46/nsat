import '../models/question_model.dart';
import '../models/test_config_model.dart';
import 'data_store.dart';

class TestDataService {
  final DataStore _dataStore = DataStore();

  Future<TestConfigModel?> getAvailableTestForCategory(String category) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return await _dataStore.getPublishedTestForCategory(category);
  }

  Future<List<QuestionModel>> fetchQuestionsForCategory(
      String category, int count) async {
    await Future.delayed(
        const Duration(milliseconds: 800)); // Simulate network load
    return _dataStore.getQuestionsByCategory(category, count);
  }
}
