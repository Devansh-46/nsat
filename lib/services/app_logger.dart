import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Log severity levels.
enum LogLevel { debug, info, error }

/// Centralized structured logger for the NSAT app.
///
/// Every service and provider calls [AppLogger] instead of `print()`.
/// Each log carries: ISO timestamp, userId, requestId, level, tag, message.
///
/// Persistence rules:
///   - **debug** → console only (stripped in release via [kDebugMode])
///   - **info**  → console; persists to Firestore when [persist] is true
///   - **error** → console + Firestore `app_logs` + Crashlytics custom keys
///
/// Usage:
/// ```dart
/// final log = AppLogger.instance;
/// log.setUserId('NIU2025MBA0472');
/// final reqId = AppLogger.generateRequestId();
/// log.info('TestProvider', 'Test started', requestId: reqId, persist: true);
/// log.error('ScoringService', 'CF failed', error: e, stackTrace: st, requestId: reqId);
/// ```
class AppLogger {
  AppLogger._();
  static final AppLogger _instance = AppLogger._();
  static AppLogger get instance => _instance;

  static const _uuid = Uuid();

  /// Firestore collection for persisted logs.
  static const String _collection = 'app_logs';

  /// Current user identifier (application_no or "admin").
  /// Set after login via [setUserId]; defaults to "anonymous".
  String _userId = 'anonymous';

  /// Whether the logger has been initialised.
  bool _initialised = false;

  // ── Public API ──────────────────────────────────────────────────────

  /// Call once after Firebase.initializeApp in main().
  void init() {
    _initialised = true;
    info('AppLogger', 'Logger initialised', persist: false);
  }

  /// Set the user ID so all subsequent logs carry it.
  void setUserId(String userId) {
    _userId = userId;
    // Also set on Crashlytics for crash correlation
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.setUserIdentifier(userId);
    }
    debug('AppLogger', 'User ID set: $userId');
  }

  /// Clear user ID on logout.
  void clearUserId() {
    _userId = 'anonymous';
    debug('AppLogger', 'User ID cleared');
  }

  /// Generate a unique request ID to trace an operation across logs.
  static String generateRequestId() => _uuid.v4().substring(0, 8);

  // ── Log methods ────────────────────────────────────────────────────

  /// Debug-level: dev console only, stripped in release builds.
  void debug(String tag, String message, {String? requestId}) {
    if (!kDebugMode) return;
    _log(LogLevel.debug, tag, message, requestId: requestId);
  }

  /// Info-level: console always; Firestore when [persist] is true.
  void info(
    String tag,
    String message, {
    String? requestId,
    bool persist = false,
  }) {
    _log(LogLevel.info, tag, message, requestId: requestId);
    if (persist && _initialised) {
      _persistToFirestore(LogLevel.info, tag, message, requestId: requestId);
    }
  }

  /// Error-level: console + Firestore + Crashlytics. Always persisted.
  void error(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? requestId,
  }) {
    _log(
      LogLevel.error,
      tag,
      message,
      error: error,
      stackTrace: stackTrace,
      requestId: requestId,
    );

    if (_initialised) {
      _persistToFirestore(
        LogLevel.error,
        tag,
        message,
        error: error,
        stackTrace: stackTrace,
        requestId: requestId,
      );
      _enrichCrashlytics(tag, message, requestId: requestId);
    }
  }

  // ── Internals ──────────────────────────────────────────────────────

  void _log(
    LogLevel level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? requestId,
  }) {
    final now = DateTime.now().toIso8601String();
    final emoji = switch (level) {
      LogLevel.debug => '🔍',
      LogLevel.info => 'ℹ️ ',
      LogLevel.error => '🔴',
    };
    final levelStr = level.name.toUpperCase().padRight(5);
    final reqStr = requestId != null ? ' [req:$requestId]' : '';
    final errStr = error != null ? '\n   └─ $error' : '';
    final line = '$emoji [$levelStr] [$tag] [$now]$reqStr $message$errStr';

    // dart:developer log — shows in DevTools and debug console
    developer.log(
      line,
      name: 'NSAT',
      level: _levelToInt(level),
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Writes a log document to Firestore `app_logs`.
  ///
  /// Fire-and-forget — never blocks the caller or throws.
  void _persistToFirestore(
    LogLevel level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? requestId,
  }) {
    try {
      final doc = <String, dynamic>{
        'timestamp': FieldValue.serverTimestamp(),
        'localTime': DateTime.now().toIso8601String(),
        'level': level.name,
        'tag': tag,
        'message': message,
        'userId': _userId,
      };

      if (requestId != null) doc['requestId'] = requestId;
      if (error != null) doc['error'] = error.toString();
      if (stackTrace != null) {
        // Cap stack trace length to avoid huge documents
        doc['stackTrace'] = stackTrace.toString().length > 1000
            ? stackTrace.toString().substring(0, 1000)
            : stackTrace.toString();
      }

      FirebaseFirestore.instance.collection(_collection).add(doc);
    } catch (_) {
      // If Firestore write fails, don't crash the app — silently drop.
    }
  }

  /// Sets Crashlytics custom keys so the next crash report carries context.
  void _enrichCrashlytics(
    String tag,
    String message, {
    String? requestId,
  }) {
    if (kIsWeb) return; // Crashlytics not supported on web
    try {
      final crashlytics = FirebaseCrashlytics.instance;
      crashlytics.setCustomKey('last_log_tag', tag);
      crashlytics.setCustomKey('last_log_message', message);
      crashlytics.setCustomKey('last_user_id', _userId);
      if (requestId != null) {
        crashlytics.setCustomKey('last_request_id', requestId);
      }
    } catch (_) {
      // Crashlytics may not be available on all platforms
    }
  }

  int _levelToInt(LogLevel level) => switch (level) {
        LogLevel.debug => 500,
        LogLevel.info => 800,
        LogLevel.error => 1000,
      };
}
