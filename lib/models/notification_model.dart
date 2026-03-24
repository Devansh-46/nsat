class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String targetCategory;
  final DateTime sentAt;
  final int deliveredCount;
  final int failedCount;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.targetCategory,
    required this.sentAt,
    this.deliveredCount = 0,
    this.failedCount = 0,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      targetCategory: json['targetCategory'] ?? 'All',
      sentAt: json['sentAt'] != null
          ? DateTime.parse(json['sentAt'])
          : DateTime.now(),
      deliveredCount: json['deliveredCount'] ?? 0,
      failedCount: json['failedCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'targetCategory': targetCategory,
      'sentAt': sentAt.toIso8601String(),
      'deliveredCount': deliveredCount,
      'failedCount': failedCount,
    };
  }
}
