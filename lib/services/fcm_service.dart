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

  /// Background message handler — must be a top-level function.
  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    AppLogger.instance
        .info(_tag, 'Background notification: ${message.notification?.title}');
  }

  /// Request notification permissions and subscribe to topics.
  Future<void> initializeForStudent(String courseKey) async {
    _log.debug(_tag, 'Initialising FCM for courseKey=$courseKey');

    // Register background handler — required for terminated/background delivery
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission (iOS + web need this; Android auto-grants)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      _log.info(_tag, 'Notification permission denied by user', persist: true);
      return;
    }

    _log.debug(_tag,
        'Notification permission granted: ${settings.authorizationStatus}');

    if (kIsWeb) return;

    await _messaging.subscribeToTopic('all_students');
    _log.info(_tag, 'Subscribed to topic: all_students');

    if (courseKey.isNotEmpty) {
      await _messaging.subscribeToTopic('school_$courseKey');
      _log.info(_tag, 'Subscribed to topic: school_$courseKey');
    }
  }

  /// Unsubscribe from all topics (on logout).
  Future<void> unsubscribeAll(String? courseKey) async {
    if (kIsWeb) return;

    _log.debug(_tag, 'Unsubscribing from all FCM topics');
    await _messaging.unsubscribeFromTopic('all_students');
    if (courseKey != null && courseKey.isNotEmpty) {
      await _messaging.unsubscribeFromTopic('school_$courseKey');
    }
    _log.info(_tag, 'Unsubscribed from all topics');
  }

  Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}