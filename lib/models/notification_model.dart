class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String target;
  final DateTime? sentAt;

  NotificationModel({
    this.id = '',
    required this.title,
    required this.body,
    this.target = 'all',
    this.sentAt,
  });
}