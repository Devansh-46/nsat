import 'package:firebase_messaging/firebase_messaging.dart';

/// Manages FCM topic subscriptions and permissions.
///
/// Students subscribe to:
///   - "all_students" (broadcast)
///   - "school_{courseKey}" (school-specific, e.g. "school_set_ug")
class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Request notification permissions and subscribe to topics.
  /// Call after successful login when the courseKey is known.
  Future<void> initializeForStudent(String courseKey) async {
    // Request permission (iOS + web need this; Android auto-grants)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return; // User declined — don't subscribe
    }

    // Subscribe to broadcast topic
    await _messaging.subscribeToTopic('all_students');

    // Subscribe to school-specific topic
    if (courseKey.isNotEmpty) {
      await _messaging.subscribeToTopic('school_$courseKey');
    }
  }

  /// Unsubscribe from all topics (on logout).
  Future<void> unsubscribeAll(String? courseKey) async {
    await _messaging.unsubscribeFromTopic('all_students');
    if (courseKey != null && courseKey.isNotEmpty) {
      await _messaging.unsubscribeFromTopic('school_$courseKey');
    }
  }

  /// Get the FCM token (useful for debugging).
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}