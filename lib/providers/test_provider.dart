import 'dart:async';
import 'package:flutter/material.dart';
import '../models/test_session_model.dart';
import '../models/test_config_model.dart';
import '../models/question_model.dart';
import '../models/user_model.dart';
import '../services/test_data_service.dart';
import '../services/data_store.dart';

class TestProvider extends ChangeNotifier {
  final TestDataService _testDataService = TestDataService();
  final DataStore _dataStore = DataStore();

  TestSessionModel? _currentSession;
  TestConfigModel? _availableTest;
  bool _isLoading = false;
  String? _error;
  Timer? _timer;

  TestSessionModel? get currentSession => _currentSession;
  TestConfigModel? get availableTest => _availableTest;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAvailableTest(String category) async {
    _setLoading(true);
    try {
      _availableTest =
          await _testDataService.getAvailableTestForCategory(category);
    } catch (e) {
      _error = 'Failed to load tests';
    }
    _setLoading(false);
  }

  Future<bool> startTest(UserModel user) async {
    if (_availableTest == null) return false;

    _setLoading(true);
    try {
      // Fetch dynamic questions
      List<QuestionModel> questions =
          await _testDataService.fetchQuestionsForCategory(
              _availableTest!.category, _availableTest!.questionCount);

      _currentSession = TestSessionModel(
        studentId: user.accsoftId,
        studentName: user.name,
        categoryName: _availableTest!.title,
        totalQuestions: _availableTest!.questionCount,
        durationMinutes: _availableTest!.durationMinutes,
        marksPerQuestion: _availableTest!.marksPerQuestion,
        negativeMarksPerWrong: _availableTest!.negativeMarking
            ? _availableTest!.negativeMarksPerWrong
            : 0.0,
        questions: questions,
      );

      _startTimer();
      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Failed to start test: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentSession != null && !_currentSession!.isSubmitted) {
        if (_currentSession!.timeRemainingSeconds > 0) {
          _currentSession!.timeRemainingSeconds--;
          notifyListeners();
        } else {
          // Auto submit on timeout
          submitTest();
        }
      } else {
        timer.cancel();
      }
    });
  }

  void selectAnswer(int questionIndex, int optionIndex) {
    if (_currentSession != null && !_currentSession!.isSubmitted) {
      _currentSession!.selectAnswer(questionIndex, optionIndex);
      notifyListeners();
    }
  }

  void clearAnswer(int questionIndex) {
    if (_currentSession != null && !_currentSession!.isSubmitted) {
      _currentSession!.clearAnswer(questionIndex);
      notifyListeners();
    }
  }

  Future<void> submitTest() async {
    if (_currentSession == null || _currentSession!.isSubmitted) return;

    _timer?.cancel();
    _setLoading(true);

    try {
      _currentSession!.submit();
      // Save result and update attempt status
      await _dataStore.saveTestResult(_currentSession!);

      _setLoading(false);
    } catch (e) {
      _error = 'Failed to submit test';
      _setLoading(false);
    }
  }

  void clearSession() {
    _timer?.cancel();
    _currentSession = null;
    _availableTest = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    if (value) _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
