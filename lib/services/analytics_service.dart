import 'package:firebase_analytics/firebase_analytics.dart';

/// Tracks key events in the NSAT student journey.
///
/// Events are visible in Firebase Console → Analytics → Events.
/// Use these to monitor exam-day funnels:
///   login_attempted → fee_verified → otp_sent → otp_verified →
///   test_started → test_submitted → result_viewed
///
/// Also tracks admin actions and error states.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService _instance = AnalyticsService._();
  static AnalyticsService get instance => _instance;

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Get the observer for MaterialApp's navigatorObservers.
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ── Student journey events ──

  /// Student entered their NIU ID and tapped Continue.
  Future<void> logLoginAttempted({required String applicationNo}) =>
      _analytics.logEvent(name: 'login_attempted', parameters: {
        'application_no': applicationNo,
      });

  /// Fee gate passed — student's payment is approved.
  Future<void> logFeeVerified({required String applicationNo}) =>
      _analytics.logEvent(name: 'fee_verified', parameters: {
        'application_no': applicationNo,
      });

  /// Fee gate blocked — student's payment is not approved.
  Future<void> logFeeBlocked({required String applicationNo}) =>
      _analytics.logEvent(name: 'fee_blocked', parameters: {
        'application_no': applicationNo,
      });

  /// OTP email sent to the student.
  Future<void> logOtpSent({required String applicationNo}) =>
      _analytics.logEvent(name: 'otp_sent', parameters: {
        'application_no': applicationNo,
      });

  /// OTP verified successfully.
  Future<void> logOtpVerified({required String applicationNo}) =>
      _analytics.logEvent(name: 'otp_verified', parameters: {
        'application_no': applicationNo,
      });

  /// Student started their test.
  Future<void> logTestStarted({
    required String applicationNo,
    required String course,
    required String testId,
  }) =>
      _analytics.logEvent(name: 'test_started', parameters: {
        'application_no': applicationNo,
        'course': course,
        'test_id': testId,
      });

  /// Test submitted (auto or manual).
  Future<void> logTestSubmitted({
    required String applicationNo,
    required String course,
    required int answeredCount,
    required int totalQuestions,
  }) =>
      _analytics.logEvent(name: 'test_submitted', parameters: {
        'application_no': applicationNo,
        'course': course,
        'answered_count': answeredCount,
        'total_questions': totalQuestions,
      });

  /// Result screen viewed by student.
  Future<void> logResultViewed({
    required String applicationNo,
    required bool showResults,
  }) =>
      _analytics.logEvent(name: 'result_viewed', parameters: {
        'application_no': applicationNo,
        'show_results': showResults.toString(),
      });

  // ── Error / block events ──

  /// Student was blocked because they already completed the test.
  Future<void> logAlreadyCompleted({required String applicationNo}) =>
      _analytics.logEvent(name: 'already_completed', parameters: {
        'application_no': applicationNo,
      });

  /// Maintenance mode blocked a student action.
  Future<void> logMaintenanceBlocked() =>
      _analytics.logEvent(name: 'maintenance_blocked');

  /// Exam window closed blocked a test start.
  Future<void> logExamWindowBlocked({required String applicationNo}) =>
      _analytics.logEvent(name: 'exam_window_blocked', parameters: {
        'application_no': applicationNo,
      });

  // ── Admin events ──

  /// Admin logged in.
  Future<void> logAdminLogin({required String email}) =>
      _analytics.logEvent(name: 'admin_login', parameters: {
        'email': email,
      });

  /// Admin sent a push notification.
  Future<void> logNotificationSent({required String target}) =>
      _analytics.logEvent(name: 'notification_sent', parameters: {
        'target': target,
      });

  /// Admin exported results CSV.
  Future<void> logResultsExported({required int count}) =>
      _analytics.logEvent(name: 'results_exported', parameters: {
        'count': count,
      });
}
