import 'package:cloud_firestore/cloud_firestore.dart';

class AppLogModel {
  final String id;
  final DateTime? timestamp;
  final String level;
  final String tag;
  final String message;
  final String userId;
  final String? requestId;
  final String? error;
  final String? stackTrace;

  AppLogModel({
    required this.id,
    this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    required this.userId,
    this.requestId,
    this.error,
    this.stackTrace,
  });

  factory AppLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppLogModel(
      id: doc.id,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
      level: data['level'] ?? 'unknown',
      tag: data['tag'] ?? 'unknown',
      message: data['message'] ?? '',
      userId: data['userId'] ?? 'anonymous',
      requestId: data['requestId'],
      error: data['error'],
      stackTrace: data['stackTrace'],
    );
  }
}
