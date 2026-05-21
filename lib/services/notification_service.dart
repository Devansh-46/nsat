import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/notification_model.dart';

/// Sends notifications via the sendNotification Cloud Function
/// and reads history from the notifications Firestore collection.
class NotificationService {
  final _db = FirebaseFirestore.instance;

  /// Send a notification via Cloud Function.
  /// [target]: "all" for broadcast, or a school key like "set_ug".
  Future<bool> send(String title, String body, String target) async {
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'asia-south1')
          .httpsCallable('sendNotification');
      await callable.call({
        'title': title,
        'body': body,
        'target': target,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Fetch notification history from Firestore.
  Future<List<NotificationModel>> getHistory() async {
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
    } catch (e) {
      return [];
    }
  }
}