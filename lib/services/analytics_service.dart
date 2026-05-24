import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

/// Tracks key events in the NSAT student journey.
///
/// FIXES Issues #28/#29: Personally Identifiable Information (PII) is
/// never sent to Firebase Analytics. Application numbers and admin emails
/// are SHA-256 hashed before being included as event parameters.
/// This complies with Google Analytics policy on PII.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService _instance = AnalyticsService._();
  static AnalyticsService get instance => _instance;

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// One-way SHA-256 hash of an identifier for analytics.
  /// Allows funnel analysis without exposing raw IDs.
  static String _hash(String value) {
    final bytes = utf8.encode(value);
    return sha256.convert(bytes).toString().substring(0, 16); // 16-char prefix
  }

  // ── Student journey events ──

  Future<void> logLoginAttempted({required String applicationNo}) =>
      _analytics.logEvent(name: 'login_attempted', parameters: {
        'app_no_hash': _hash(applicationNo), // FIXED: hash instead of raw ID
      });

  Future<void> logFeeVerified({required String applicationNo}) =>
      _analytics.logEvent(name: 'fee_verified', parameters: {
        'app_no_hash': _hash(applicationNo),
      });

  Future<void> logFeeBlocked({required String applicationNo}) =>
      _analytics.logEvent(name: 'fee_blocked', parameters: {
        'app_no_hash': _hash(applicationNo),
      });

  Future<void> logOtpSent({required String applicationNo}) =>
      _analytics.logEvent(name: 'otp_sent', parameters: {
        'app_no_hash': _hash(applicationNo),
      });

  Future<void> logOtpVerified({required String applicationNo}) =>
      _analytics.logEvent(name: 'otp_verified', parameters: {
        'app_no_hash': _hash(applicationNo),
      });

  Future<void> logTestStarted({
    required String applicationNo,
    required String course,
    required String testId,
  }) =>
      _analytics.logEvent(name: 'test_started', parameters: {
        'app_no_hash': _hash(applicationNo),
        'course': course,
        'test_id': testId,
      });

  Future<void> logTestSubmitted({
    required String applicationNo,
    required String course,
    required int answeredCount,
    required int totalQuestions,
  }) =>
      _analytics.logEvent(name: 'test_submitted', parameters: {
        'app_no_hash': _hash(applicationNo),
        'course': course,
        'answered_count': answeredCount,
        'total_questions': totalQuestions,
      });

  Future<void> logResultViewed({
    required String applicationNo,
    required bool showResults,
  }) =>
      _analytics.logEvent(name: 'result_viewed', parameters: {
        'app_no_hash': _hash(applicationNo),
        'show_results': showResults.toString(),
      });

  // ── Error / block events ──

  Future<void> logAlreadyCompleted({required String applicationNo}) =>
      _analytics.logEvent(name: 'already_completed', parameters: {
        'app_no_hash': _hash(applicationNo),
      });

  Future<void> logMaintenanceBlocked() =>
      _analytics.logEvent(name: 'maintenance_blocked');

  Future<void> logExamWindowBlocked({required String applicationNo}) =>
      _analytics.logEvent(name: 'exam_window_blocked', parameters: {
        'app_no_hash': _hash(applicationNo),
      });

  // ── Admin events ──

  /// FIXES Issue #29: Admin email is hashed — raw email was PII in analytics.
  Future<void> logAdminLogin({required String email}) =>
      _analytics.logEvent(name: 'admin_login', parameters: {
        'email_hash': _hash(email), // FIXED: hash instead of raw email
      });

  Future<void> logNotificationSent({required String target}) =>
      _analytics.logEvent(name: 'notification_sent', parameters: {
        'target': target,
      });

  Future<void> logResultsExported({required int count}) =>
      _analytics.logEvent(name: 'results_exported', parameters: {
        'count': count,
      });
}
