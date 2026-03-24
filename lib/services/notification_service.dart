import '../models/notification_model.dart';
import 'data_store.dart';

class NotificationService {
  final DataStore _dataStore = DataStore();

  Future<NotificationModel> sendPushNotification({
    required String title,
    required String body,
    required String category,
    bool scheduleLater = false,
  }) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate FCM

    // Mock delivery logic: 'All' sends to 1842 devices, specific category sends to ~300
    int delivered = category == 'All' ? 1842 : 350;

    final notif = NotificationModel(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      targetCategory: category,
      sentAt: DateTime.now(),
      deliveredCount: delivered,
      failedCount: 0,
    );

    await _dataStore.saveNotification(notif);
    return notif;
  }

  Future<List<NotificationModel>> getHistory() async {
    return await _dataStore.getNotifications();
  }
}
