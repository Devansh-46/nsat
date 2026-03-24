import '../models/test_config_model.dart';
import '../models/test_session_model.dart';
import 'data_store.dart';

class AdminService {
  final DataStore _dataStore = DataStore();

  Future<Map<String, dynamic>> getDashboardStats() async {
    await Future.delayed(const Duration(milliseconds: 600)); // Simulate network

    final results = await _dataStore.getAllTestResults();
    final configs = await _dataStore.getTestConfigs();

    int activeTests = configs.where((c) => c.isPublished).length;
    int totalAttempts = results.length;

    return {
      'onlineToday': 234 + totalAttempts, // Mock dynamic number
      'activeTests': activeTests,
      'totalAttempts': totalAttempts,
      'pushFailed': 0, // Simplified for now
    };
  }

  Future<void> createTestConfig(TestConfigModel config) async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate publish
    await _dataStore.saveTestConfig(config);
  }

  Future<List<TestSessionModel>> getAllResults() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return await _dataStore.getAllTestResults();
  }
}
