import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Log severity levels.
enum LogLevel { debug, info, error }

/// Centralized structured logger for the NSAT app.
///
/// FIXES Issue #30: Log writes are now buffered in memory and flushed
/// to Firestore in batches of up to 20, at most once every 5 seconds.
/// This prevents unbounded individual Firestore writes that could exhaust
/// the free tier quota at exam-day scale (hundreds of concurrent users).
class AppLogger {
  AppLogger._();
  static final AppLogger _instance = AppLogger._();
  static AppLogger get instance => _instance;

  static const _uuid = Uuid();
  static const String _collection = 'app_logs';

  // Batching configuration
  static const int _maxBatchSize = 20;
  static const Duration _flushInterval = Duration(seconds: 5);

  String _userId = 'anonymous';
  bool _initialised = false;

  /// Pending log docs waiting to be flushed to Firestore.
  final List<Map<String, dynamic>> _buffer = [];
  Timer? _flushTimer;

  // ── Public API ──────────────────────────────────────────────────────

  void init() {
    _initialised = true;
    _flushTimer = Timer.periodic(_flushInterval, (_) => _flushBuffer());
    info('AppLogger', 'Logger initialised', persist: false);
  }

  void setUserId(String userId) {
    _userId = userId;
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.setUserIdentifier(userId);
    }
    debug('AppLogger', 'User ID set: $userId');
  }

  void clearUserId() {
    _userId = 'anonymous';
    debug('AppLogger', 'User ID cleared');
  }

  static String generateRequestId() => _uuid.v4().substring(0, 8);

  // ── Log methods ────────────────────────────────────────────────────

  void debug(String tag, String message, {String? requestId}) {
    if (!kDebugMode) return;
    _log(LogLevel.debug, tag, message, requestId: requestId);
  }

  void info(
    String tag,
    String message, {
    String? requestId,
    bool persist = false,
  }) {
    _log(LogLevel.info, tag, message, requestId: requestId);
    if (persist && _initialised) {
      _enqueueToBuffer(LogLevel.info, tag, message, requestId: requestId);
    }
  }

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
      _enqueueToBuffer(
        LogLevel.error,
        tag,
        message,
        error: error,
        stackTrace: stackTrace,
        requestId: requestId,
      );
      _enrichCrashlytics(tag, message, requestId: requestId);

      // Flush immediately for errors — don't wait for the timer
      _flushBuffer();
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

    developer.log(
      line,
      name: 'NSAT',
      level: _levelToInt(level),
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Adds a log entry to the in-memory buffer.
  /// Flushes immediately if the buffer hits max batch size.
  void _enqueueToBuffer(
    LogLevel level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? requestId,
  }) {
    try {
      final doc = <String, dynamic>{
        'localTime': DateTime.now().toIso8601String(),
        'level': level.name,
        'tag': tag,
        'message': message,
        'userId': _userId,
      };

      if (requestId != null) doc['requestId'] = requestId;
      if (error != null) doc['error'] = error.toString();
      if (stackTrace != null) {
        doc['stackTrace'] = stackTrace.toString().length > 1000
            ? stackTrace.toString().substring(0, 1000)
            : stackTrace.toString();
      }

      _buffer.add(doc);

      if (_buffer.length >= _maxBatchSize) {
        _flushBuffer();
      }
    } catch (_) {
      // Never crash the app for a logging failure
    }
  }

  /// Flushes the buffer to Firestore using a batch write.
  /// Uses a Firestore batch (max 500 writes) for efficiency.
  void _flushBuffer() {
    if (_buffer.isEmpty) return;

    // Take a snapshot of current buffer and clear it
    final toWrite = List<Map<String, dynamic>>.from(_buffer);
    _buffer.clear();

    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();
      final serverTs = FieldValue.serverTimestamp();

      for (final doc in toWrite) {
        final ref = db.collection(_collection).doc();
        // Add server timestamp alongside local time
        batch.set(ref, {...doc, 'timestamp': serverTs});
      }

      batch.commit().catchError((e) {
        // If flush fails, silently drop — don't crash the app
        developer.log('AppLogger: Firestore flush failed: $e', name: 'NSAT');
      });
    } catch (_) {
      // Never crash the app for a logging failure
    }
  }

  void _enrichCrashlytics(
    String tag,
    String message, {
    String? requestId,
  }) {
    if (kIsWeb) return;
    try {
      final crashlytics = FirebaseCrashlytics.instance;
      crashlytics.setCustomKey('last_log_tag', tag);
      crashlytics.setCustomKey('last_log_message', message);
      crashlytics.setCustomKey('last_user_id', _userId);
      if (requestId != null) {
        crashlytics.setCustomKey('last_request_id', requestId);
      }
    } catch (_) {}
  }

  int _levelToInt(LogLevel level) => switch (level) {
        LogLevel.debug => 500,
        LogLevel.info => 800,
        LogLevel.error => 1000,
      };

  /// Call on app shutdown to flush any remaining buffered logs.
  Future<void> dispose() async {
    _flushTimer?.cancel();
    _flushBuffer();
  }
}
