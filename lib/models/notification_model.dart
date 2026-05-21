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

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'target': target,
        'sentAt': sentAt?.toIso8601String(),
      };

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        body: json['body'] ?? '',
        target: json['target'] ?? 'all',
        sentAt: json['sentAt'] != null ? DateTime.parse(json['sentAt']) : null,
      );
}