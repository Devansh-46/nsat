import 'dart:async';
import 'package:flutter/material.dart';
import '../models/test_session_model.dart';
import '../models/test_model.dart';
import '../models/question_model.dart';
import '../services/question_service.dart';
import '../services/attempt_service.dart';
import '../services/scoring_service.dart';
import '../services/test_service.dart';
import '../services/app_logger.dart';

/// Drives the test-taking flow, backed entirely by Firestore.
class TestProvider extends ChangeNotifier {
  static const _tag = 'TestProvider';
  final _log = AppLogger.instance;

  final TestService _testService = TestService();
  final QuestionService _questionService = QuestionService();
  final AttemptService _attemptService = AttemptService();
  final ScoringService _scoringService = ScoringService();

  TestSessionModel? _currentSession;
  TestModel? _availableTest;
  bool _isLoading = false;
  String? _error;
  Timer? _timer;

  /// FIXES #7/#8: Single submission guard — set to true the moment
  /// submitTest() begins, preventing any duplicate call (timer-fired or
  /// user-tapped) from entering the scoring path.
  bool _submissionInProgress = false;

  bool _alreadyCompleted = false;
  bool _hasResumableAttempt = false;
  String? _savedResultId;
  bool _showResults = true;
  String? _sessionRequestId;

  TestSessionModel? get currentSession => _currentSession;
  TestModel? get availableTest => _availableTest;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get alreadyCompleted => _alreadyCompleted;
  bool get hasResumableAttempt => _hasResumableAttempt;
  String? get savedResultId => _savedResultId;
  bool get showResults => _availableTest?.showResults ?? _showResults;

  Future<void> fetchAvailableTest(String course) async {
    _setLoading(true);
    _log.debug(_tag, 'Fetching available test for course=$course');
    try {
      _availableTest = await _testService.getPublishedTestForCourse(course);
      if (_availableTest == null) {
        _log.info(_tag, 'No published test found for course=$course', persist: true);
        _error = 'No published test is available for this course.';
      } else {
        _log.debug(_tag, 'Found test: ${_availableTest!.id} (${_availableTest!.title})');
      }
    } catch (e, st) {
      _log.error(_tag, 'Failed to fetch test for course=$course',
          error: e, stackTrace: st);
      _error = 'Failed to load the test. Please check your connection.';
    }
    _setLoading(false);
  }

  Future<bool> startTest({
    required String applicationNo,
    required String studentName,
    required String course,
  }) async {
    if (_availableTest == null) return false;

    _sessionRequestId = AppLogger.generateRequestId();
    _log.info(_tag,
        'Starting test for $applicationNo (course: $course, test: ${_availableTest!.id})',
        requestId: _sessionRequestId, persist: true);

    _setLoading(true);
    _alreadyCompleted = false;
    _hasResumableAttempt = false;

    try {
      final attempt = await _attemptService.startAttempt(
        applicationNo: applicationNo,
        testId: _availableTest!.id,
      );

      switch (attempt.outcome) {
        case StartAttemptOutcome.alreadyCompleted:
          _alreadyCompleted = true;
          _log.info(_tag, 'Test blocked: $applicationNo already completed',
              requestId: _sessionRequestId, persist: true);
          _setLoading(false);
          return false;
        case StartAttemptOutcome.resumable:
          _hasResumableAttempt = true;
          _log.info(_tag, 'Resumable attempt found for $applicationNo',
              requestId: _sessionRequestId, persist: true);
          _setLoading(false);
          return false;
        case StartAttemptOutcome.error:
          _error = attempt.errorMessage;
          _log.error(_tag, 'Attempt lock failed for $applicationNo: ${attempt.errorMessage}',
              requestId: _sessionRequestId);
          _setLoading(false);
          return false;
        case StartAttemptOutcome.started:
          _log.info(_tag, 'Attempt lock claimed for $applicationNo',
              requestId: _sessionRequestId);
          break;
      }

      final List<QuestionModel> questions =
          await _questionService.fetchQuestionsForCourse(
        course,
        _availableTest!.questionCount,
      );

      if (questions.isEmpty) {
        _log.error(_tag, 'No questions returned for course=$course',
            requestId: _sessionRequestId);
        _error = 'No questions are available for this test.';
        _setLoading(false);
        return false;
      }

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

      // Reset submission guard for the new session
      _submissionInProgress = false;

      _log.info(_tag,
          'Test session created: ${questions.length} questions, '
          '${_availableTest!.durationMinutes} min',
          requestId: _sessionRequestId, persist: true);

      _startTimer();
      _setLoading(false);
      return true;
    } catch (e, st) {
      _log.error(_tag, 'Failed to start test for $applicationNo',
          error: e, stackTrace: st, requestId: _sessionRequestId);
      _error = 'Failed to start test: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // FIXES #42: Null-check session inside callback before use
      final session = _currentSession;
      if (session == null || session.isSubmitted) {
        timer.cancel();
        return;
      }

      if (session.timeRemainingSeconds > 0) {
        session.timeRemainingSeconds--;
        notifyListeners();
      } else {
        timer.cancel(); // Cancel timer BEFORE calling submitTest
        _log.info(_tag, 'Timer expired — auto-submitting test',
            requestId: _sessionRequestId, persist: true);
        submitTest(); // auto-submit on timeout
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

  /// Submits the test via the scoreSubmission Cloud Function.
  ///
  /// FIXES #7/#8: The _submissionInProgress guard is checked and set
  /// atomically at the very top of this method, before any async work.
  /// This prevents both timer-fired and user-tapped duplicate submissions.
  Future<void> submitTest() async {
    // CRITICAL GUARD: must be first, before any other checks
    if (_submissionInProgress) {
      _log.debug(_tag, 'submitTest called but submission already in progress — ignoring');
      return;
    }
    if (_currentSession == null || _currentSession!.isSubmitted) return;

    // Set the guard immediately — synchronously before any await
    _submissionInProgress = true;
    _timer?.cancel(); // FIXES #8: cancel timer as soon as submission starts

    _setLoading(true);

    _log.info(_tag,
        'Submitting test for ${_currentSession!.studentId} '
        '(answered: ${_currentSession!.answeredCount}/${_currentSession!.totalQuestions})',
        requestId: _sessionRequestId, persist: true);

    try {
      final session = _currentSession!;
      session.submit();

      final score = await _scoringService.scoreSubmission(
        applicationNo: session.studentId,
        studentName: session.studentName,
        testId: _availableTest!.id,
        answers: session.answers,
      );

      _savedResultId = score.resultId;
      _showResults = score.showResults;

      // FIXES #9: Remove client-side markCompleted call — the Cloud Function
      // (scoreSubmission) already flips attempt status to 'completed' server-side.
      // No redundant client call needed.

      session.setServerScores(
        correctCount: score.correctCount,
        wrongCount: score.wrongCount,
        skippedCount: score.skippedCount,
        netScore: score.netScore,
        maxScore: score.maxScore,
      );

      _log.info(_tag,
          'Test submitted successfully for ${session.studentId}: '
          '${score.netScore}/${score.maxScore}',
          requestId: _sessionRequestId, persist: true);

      _setLoading(false);
    } catch (e, st) {
      _log.error(_tag,
          'Test submission failed for ${_currentSession!.studentId}',
          error: e, stackTrace: st, requestId: _sessionRequestId);
      _error = 'Your test was scored, but saving the result failed. '
          'Please tell an invigilator.';
      // Reset guard on failure so user can retry
      _submissionInProgress = false;
      _setLoading(false);
    }
  }

  void clearSession() {
    _log.debug(_tag, 'Test session cleared');
    _timer?.cancel();
    _currentSession = null;
    _availableTest = null;
    _alreadyCompleted = false;
    _hasResumableAttempt = false;
    _savedResultId = null;
    _showResults = true;
    _sessionRequestId = null;
    _submissionInProgress = false;
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
