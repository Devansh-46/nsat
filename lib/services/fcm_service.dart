import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'app_logger.dart';

/// Manages FCM topic subscriptions and permissions.
///
/// Students subscribe to:
///   - "all_students" (broadcast)
///   - "school_{courseKey}" (school-specific, e.g. "school_set_ug")
class FcmService {
  static const _tag = 'FcmService';
  final _log = AppLogger.instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Request notification permissions and subscribe to topics.
  /// Call after successful login when the courseKey is known.
  Future<void> initializeForStudent(String courseKey) async {
    _log.debug(_tag, 'Initialising FCM for courseKey=$courseKey');

    // Request permission (iOS + web need this; Android auto-grants)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      _log.info(_tag, 'Notification permission denied by user', persist: true);
      return; // User declined — don't subscribe
    }

    _log.debug(_tag, 'Notification permission granted: ${settings.authorizationStatus}');

    if (kIsWeb) return; // Topic subscription is not supported on Web

    // Subscribe to broadcast topic
    await _messaging.subscribeToTopic('all_students');
    _log.info(_tag, 'Subscribed to topic: all_students');

    // Subscribe to school-specific topic
    if (courseKey.isNotEmpty) {
      await _messaging.subscribeToTopic('school_$courseKey');
      _log.info(_tag, 'Subscribed to topic: school_$courseKey');
    }
  }

  /// Unsubscribe from all topics (on logout).
  Future<void> unsubscribeAll(String? courseKey) async {
    if (kIsWeb) return; // Topic subscription is not supported on Web
    
    _log.debug(_tag, 'Unsubscribing from all FCM topics');
    await _messaging.unsubscribeFromTopic('all_students');
    if (courseKey != null && courseKey.isNotEmpty) {
      await _messaging.unsubscribeFromTopic('school_$courseKey');
    }
    _log.info(_tag, 'Unsubscribed from all topics');
  }

  /// Get the FCM token (useful for debugging).
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}