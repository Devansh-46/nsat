import 'dart:async';
import 'package:flutter/material.dart';
import '../models/test_session_model.dart';
import '../models/test_model.dart';
import '../models/question_model.dart';
import '../services/question_service.dart';
import '../services/result_service.dart';
import '../services/attempt_service.dart';
import '../services/scoring_service.dart';
import '../services/test_service.dart';

/// Drives the test-taking flow, backed entirely by Firestore.
///
/// REWIRE NOTE: this provider no longer depends on UserModel or the mock
/// DataStore. `startTest` takes DATA_MODEL.md identifiers directly —
/// applicationNo, studentName, course — which AuthProvider already holds
/// after the fee gate. The old ACCSOFT-era path is gone.
class TestProvider extends ChangeNotifier {
  final TestService _testService = TestService();
  final QuestionService _questionService = QuestionService();
  final AttemptService _attemptService = AttemptService();
  final ScoringService _scoringService = ScoringService();

  TestSessionModel? _currentSession;
  TestModel? _availableTest;
  bool _isLoading = false;
  String? _error;
  Timer? _timer;

  /// Set when startTest is blocked because the student already finished.
  bool _alreadyCompleted = false;

  /// Set when an earlier unfinished attempt was found for this student.
  bool _hasResumableAttempt = false;

  /// The result document ID, available after a successful submission.
  String? _savedResultId;

  TestSessionModel? get currentSession => _currentSession;
  TestModel? get availableTest => _availableTest;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get alreadyCompleted => _alreadyCompleted;
  bool get hasResumableAttempt => _hasResumableAttempt;
  String? get savedResultId => _savedResultId;

  /// Loads the published test for a course. [course] is the canonical
  /// course key (e.g. "btech").
  Future<void> fetchAvailableTest(String course) async {
    _setLoading(true);
    try {
      _availableTest = await _testService.getPublishedTestForCourse(course);
      if (_availableTest == null) {
        _error = 'No published test is available for this course.';
      }
    } catch (e) {
      _error = 'Failed to load the test. Please check your connection.';
    }
    _setLoading(false);
  }

  /// Starts the test for a student, identified by DATA_MODEL.md fields.
  ///
  /// Claims the one-attempt lock transactionally BEFORE loading questions,
  /// so a blocked or resumable student never sees the paper. Returns true
  /// only when a fresh session was created.
  Future<bool> startTest({
    required String applicationNo,
    required String studentName,
    required String course,
  }) async {
    if (_availableTest == null) return false;

    _setLoading(true);
    _alreadyCompleted = false;
    _hasResumableAttempt = false;

    try {
      // 1. Claim the attempt lock first (transactional).
      final attempt = await _attemptService.startAttempt(
        applicationNo: applicationNo,
        testId: _availableTest!.id,
      );

      switch (attempt.outcome) {
        case StartAttemptOutcome.alreadyCompleted:
          _alreadyCompleted = true;
          _setLoading(false);
          return false;
        case StartAttemptOutcome.resumable:
          // An earlier attempt never finished. Phase 1 surfaces this to
          // the UI rather than silently letting them re-sit.
          _hasResumableAttempt = true;
          _setLoading(false);
          return false;
        case StartAttemptOutcome.error:
          _error = attempt.errorMessage;
          _setLoading(false);
          return false;
        case StartAttemptOutcome.started:
          break; // lock claimed — continue
      }

      // 2. Load questions for the course.
      final List<QuestionModel> questions =
          await _questionService.fetchQuestionsForCourse(
        course,
        _availableTest!.questionCount,
      );

      if (questions.isEmpty) {
        _error = 'No questions are available for this test.';
        _setLoading(false);
        return false;
      }

      // 3. Build the session.
      _currentSession = TestSessionModel(
        studentId: applicationNo,
        studentName: studentName,
        categoryName: _availableTest!.title,
        totalQuestions: questions.length,
        durationMinutes: _availableTest!.durationMinutes,
        marksPerQuestion: _availableTest!.marksPerQuestion,
        negativeMarksPerWrong: _availableTest!.effectiveNegativeMarks,
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
          submitTest(); // auto-submit on timeout
        }
      } else {
        timer.cancel();
      }
    });
  }

  void selectAnswer(int questionIndex, dynamic answer) {
    if (_currentSession != null && !_currentSession!.isSubmitted) {
      _currentSession!.selectAnswer(questionIndex, answer);
      notifyListeners();
    }
  }

  void clearAnswer(int questionIndex) {
    if (_currentSession != null && !_currentSession!.isSubmitted) {
      _currentSession!.clearAnswer(questionIndex);
      notifyListeners();
    }
  }

  /// Submits the test: scores server-side via Cloud Function, which also
  /// writes the result doc and flips the attempt lock.
  Future<void> submitTest() async {
    if (_currentSession == null || _currentSession!.isSubmitted) return;

    _timer?.cancel();
    _setLoading(true);

    try {
      final session = _currentSession!;
      session.submit();

      // Server-side scoring — the Cloud Function reads questions,
      // scores, writes the result, and flips the attempt lock.
      final score = await _scoringService.scoreSubmission(
        applicationNo: session.studentId,
        studentName: session.studentName,
        testId: _availableTest!.id,
        answers: session.answers,
      );

      _savedResultId = score.resultId;

      // Update session with server-returned scores for the result screen.
      session.setServerScores(
        correctCount: score.correctCount,
        wrongCount: score.wrongCount,
        skippedCount: score.skippedCount,
        netScore: score.netScore,
        maxScore: score.maxScore,
      );

      _setLoading(false);
    } catch (e) {
      _error = 'Your test was scored, but saving the result failed. '
          'Please tell an invigilator.';
      _setLoading(false);
    }
  }

  void clearSession() {
    _timer?.cancel();
    _currentSession = null;
    _availableTest = null;
    _alreadyCompleted = false;
    _hasResumableAttempt = false;
    _savedResultId = null;
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
