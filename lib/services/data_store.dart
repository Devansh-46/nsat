import '../models/user_model.dart';
import '../models/question_model.dart';
import '../models/test_config_model.dart';
import '../models/test_session_model.dart';
import '../models/notification_model.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DataStore {
  static final DataStore _instance = DataStore._internal();
  factory DataStore() => _instance;
  DataStore._internal();

  // In-memory seeded data
  final List<UserModel> _students = [
    UserModel(
      id: 'student_1',
      accsoftId: 'NIU2025MBA0472',
      name: 'Rahul Sharma',
      role: 'student',
      course: 'MBA — Management',
      feePaid: true,
      feeAmount: 1100.0,
      hasAttempted: false,
    ),
    UserModel(
      id: 'student_2',
      accsoftId: 'NIU2025BT0183',
      name: 'Priya Patel',
      role: 'student',
      course: 'B.Tech / Engineering',
      feePaid: false,
      feeAmount: 1100.0,
      hasAttempted: false,
    ),
    UserModel(
      id: 'student_3',
      accsoftId: 'NIU2025LLB0091',
      name: 'Amit Kumar',
      role: 'student',
      course: 'LLB',
      feePaid: true,
      hasAttempted: true,
    ),
  ];

  final List<TestConfigModel> _defaultTestConfigs = [
    TestConfigModel(
      id: 'test_mba_1',
      title: 'NIU-SAT MBA — June 2025',
      category: 'MBA — Management',
      questionCount: 60,
      durationMinutes: 60,
      marksPerQuestion: 1.0,
      negativeMarking: true,
      negativeMarksPerWrong: 0.25,
      isPublished: true,
    ),
    TestConfigModel(
      id: 'test_bt_1',
      title: 'NIU-SAT B.Tech — June 2025',
      category: 'B.Tech / Engineering',
      questionCount: 60,
      durationMinutes: 60,
      marksPerQuestion: 1.0,
      negativeMarking: true,
      negativeMarksPerWrong: 0.25,
      isPublished: true,
    ),
  ];

  List<QuestionModel> getQuestionsByCategory(String category, int count) {
    // Generate realistic seeded questions based on category
    return List.generate(count, (index) {
      if (category == 'MBA — Management') {
        return QuestionModel(
          id: 'q_mba_$index',
          category: category,
          text:
              'MBA Question ${index + 1}: Which of the following is NOT a characteristic of a perfectly competitive market?',
          options: [
            'Large number of buyers and sellers',
            'Product differentiation',
            'Free entry and exit of firms',
            'Perfect information to all parties',
          ],
          correctAnswerIndex: 1, // 'Product differentiation'
        );
      } else if (category == 'B.Tech / Engineering') {
        return QuestionModel(
          id: 'q_bt_$index',
          category: category,
          text:
              'B.Tech Question ${index + 1}: What is the time complexity of binary search?',
          options: ['O(1)', 'O(n)', 'O(log n)', 'O(n^2)'],
          correctAnswerIndex: 2,
        );
      } else {
        return QuestionModel(
          id: 'q_gen_$index',
          category: category,
          text:
              'General Question ${index + 1} for $category. Identify the correct option.',
          options: ['Option A', 'Option B', 'Option C', 'Option D'],
          correctAnswerIndex: index % 4,
        );
      }
    });
  }

  // --- Methods ---

  Future<UserModel?> getStudentByAccsoftId(String accsoftId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    try {
      return _students.firstWhere((s) => s.accsoftId == accsoftId);
    } catch (e) {
      return null;
    }
  }

  Future<void> markStudentAttempted(String accsoftId) async {
    final index = _students.indexWhere((s) => s.accsoftId == accsoftId);
    if (index != -1) {
      _students[index] = _students[index].copyWith(hasAttempted: true);
    }
  }

  // Persisted Test Results
  Future<void> saveTestResult(TestSessionModel session) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> resultsJson = prefs.getStringList('test_results') ?? [];
    resultsJson.add(jsonEncode(session.toJson()));
    await prefs.setStringList('test_results', resultsJson);

    // Also mark student as attempted
    await markStudentAttempted(
        session.studentId); // Assuming studentId here is the accsoftId
  }

  Future<List<TestSessionModel>> getAllTestResults() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> resultsJson = prefs.getStringList('test_results') ?? [];
    return resultsJson
        .map((jsonStr) => TestSessionModel.fromJson(jsonDecode(jsonStr)))
        .toList();
  }

  // Persisted Test Configs
  Future<List<TestConfigModel>> getTestConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? configsJson = prefs.getStringList('test_configs');
    if (configsJson == null) {
      // Initialize with defaults if empty
      final defaultJsonList =
          _defaultTestConfigs.map((c) => jsonEncode(c.toJson())).toList();
      await prefs.setStringList('test_configs', defaultJsonList);
      return _defaultTestConfigs;
    }
    return configsJson
        .map((jsonStr) => TestConfigModel.fromJson(jsonDecode(jsonStr)))
        .toList();
  }

  Future<TestConfigModel?> getPublishedTestForCategory(String category) async {
    final configs = await getTestConfigs();
    try {
      return configs.firstWhere((c) => c.category == category && c.isPublished);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveTestConfig(TestConfigModel config) async {
    final prefs = await SharedPreferences.getInstance();
    final configs = await getTestConfigs();
    configs.add(config);
    await prefs.setStringList(
        'test_configs', configs.map((c) => jsonEncode(c.toJson())).toList());
  }

  // Persisted Notifications
  Future<void> saveNotification(NotificationModel notification) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> notifsJson = prefs.getStringList('notifications') ?? [];
    notifsJson.add(jsonEncode(notification.toJson()));
    await prefs.setStringList('notifications', notifsJson);
  }

  Future<List<NotificationModel>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> notifsJson = prefs.getStringList('notifications') ?? [];
    return notifsJson
        .map((jsonStr) => NotificationModel.fromJson(jsonDecode(jsonStr)))
        .toList()
        .reversed
        .toList(); // Newest first
  }
}
