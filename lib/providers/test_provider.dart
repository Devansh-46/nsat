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
///
/// REWIRE NOTE: this provider no longer depends on UserModel or the mock
/// DataStore. `startTest` takes DATA_MODEL.md identifiers directly —
/// applicationNo, studentName, course — which AuthProvider already holds
/// after the fee gate. The old ACCSOFT-era path is gone.
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

  /// Set when startTest is blocked because the student already finished.
  bool _alreadyCompleted = false;

  /// Set when an earlier unfinished attempt was found for this student.
  bool _hasResumableAttempt = false;

  /// The result document ID, available after a successful submission.
  String? _savedResultId;

  /// Whether the current test is configured to show results to students.
  bool _showResults = true;

  /// Request ID for the current test session lifecycle.
  String? _sessionRequestId;

  TestSessionModel? get currentSession => _currentSession;
  TestModel? get availableTest => _availableTest;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get alreadyCompleted => _alreadyCompleted;
  bool get hasResumableAttempt => _hasResumableAttempt;
  String? get savedResultId => _savedResultId;

  /// True when the test allows students to see their score breakdown.
  bool get showResults => _showResults;

  /// Loads the published test for a course. [course] is the canonical
  /// course key (e.g. "btech").
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

    _sessionRequestId = AppLogger.generateRequestId();
    _log.info(_tag,
        'Starting test for $applicationNo (course: $course, test: ${_availableTest!.id})',
        requestId: _sessionRequestId, persist: true);

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
          _log.info(_tag, 'Test blocked: $applicationNo already completed',
              requestId: _sessionRequestId, persist: true);
          _setLoading(false);
          return false;
        case StartAttemptOutcome.resumable:
          // An earlier attempt never finished. Phase 1 surfaces this to
          // the UI rather than silently letting them re-sit.
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
          break; // lock claimed — continue
      }

      // 2. Load questions for the course.
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
      if (_currentSession != null && !_currentSession!.isSubmitted) {
        if (_currentSession!.timeRemainingSeconds > 0) {
          _currentSession!.timeRemainingSeconds--;
          notifyListeners();
        } else {
          _log.info(_tag, 'Timer expired — auto-submitting test',
              requestId: _sessionRequestId, persist: true);
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

    _log.info(_tag,
        'Submitting test for ${_currentSession!.studentId} '
        '(answered: ${_currentSession!.answeredCount}/${_currentSession!.totalQuestions})',
        requestId: _sessionRequestId, persist: true);

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
      _showResults = score.showResults;

      // Update session with server-returned scores for the result screen.
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
