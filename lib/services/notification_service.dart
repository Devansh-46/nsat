import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/notification_model.dart';
import 'app_logger.dart';

/// Sends notifications via the sendNotification Cloud Function
/// and reads history from the notifications Firestore collection.
class NotificationService {
  static const _tag = 'NotificationService';
  final _log = AppLogger.instance;

  final _db = FirebaseFirestore.instance;

  /// Send a notification via Cloud Function.
  /// [target]: "all" for broadcast, or a school key like "set_ug".
  Future<bool> send(String title, String body, String target) async {
    final reqId = AppLogger.generateRequestId();
    _log.info(_tag, 'Sending notification: target=$target, title="$title"',
        requestId: reqId, persist: true);

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'asia-south1')
          .httpsCallable('sendNotification');
      await callable.call({
        'title': title,
        'body': body,
        'target': target,
      });
      _log.info(_tag, 'Notification sent successfully to $target',
          requestId: reqId, persist: true);
      return true;
    } catch (e, st) {
      _log.error(_tag, 'Failed to send notification to $target',
          error: e, stackTrace: st, requestId: reqId);
      return false;
    }
  }

  /// Fetch notification history from Firestore.
  Future<List<NotificationModel>> getHistory() async {
    _log.debug(_tag, 'Fetching notification history');
    try {
      final snapshot = await _db
          .collection('notifications')
          .orderBy('sentAt', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return NotificationModel(
          id: doc.id,
          title: data['title'] ?? '',
          body: data['body'] ?? '',
          target: data['target'] ?? 'all',
          sentAt: (data['sentAt'] as Timestamp?)?.toDate(),
        );
      }).toList();
    } catch (e, st) {
      _log.error(_tag, 'Failed to fetch notification history',
          error: e, stackTrace: st);
      return [];
    }
  }
}