import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_logger.dart';

class QuestionManagementService {
  static const _tag = 'QuestionManagementService';
  final _log = AppLogger.instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetch questions for a course, reading both public `questions` and private `answers`.
  Future<List<Map<String, dynamic>>> fetchForCourse(String course) async {
    final reqId = AppLogger.generateRequestId();
    try {
      final qSnap = await _db
          .collection('questions')
          .where('course', isEqualTo: course)
          .get();

      if (qSnap.docs.isEmpty) return [];

      // Sort by sequence manually
      final sortedDocs = qSnap.docs.toList()
        ..sort((a, b) {
          final seqA = (a.data()['sequence'] as num?)?.toInt() ?? 9999;
          final seqB = (b.data()['sequence'] as num?)?.toInt() ?? 9999;
          return seqA.compareTo(seqB);
        });

      // Batch read answers would be ideal, but for now we'll do individual reads
      // or chunked get. We can just use Future.wait for simplicity if count isn't massive.
      // Or we can just read all answers if rules allow. Let's do individual for now.
      
      final futures = sortedDocs.map((doc) async {
        final data = doc.data();
        data['id'] = doc.id;
        
        try {
          final ansDoc = await _db.collection('answers').doc(doc.id).get();
          if (ansDoc.exists) {
            final ansData = ansDoc.data() ?? {};
            if (ansData.containsKey('correctAnswerIndex')) {
              data['correctAnswerIndex'] = ansData['correctAnswerIndex'];
            }
            if (ansData.containsKey('correctAnswerTexts')) {
              data['correctAnswerTexts'] = ansData['correctAnswerTexts'];
            }
          }
        } catch (e) {
          _log.error(_tag, 'Failed to fetch answer for ${doc.id}', error: e);
        }
        return data;
      });

      final fullData = await Future.wait(futures);
      return fullData.toList();
    } catch (e, st) {
      _log.error(_tag, 'Failed to fetch questions for $course', error: e, stackTrace: st, requestId: reqId);
      rethrow;
    }
  }

  /// Create a new question. Writes to both `questions` and `answers` in a batch.
  Future<void> createQuestion(Map<String, dynamic> data) async {
    final batch = _db.batch();
    final newRef = _db.collection('questions').doc();

    final isMcq = (data['type'] ?? 'multipleChoice') == 'multipleChoice';

    final qData = {
      'text': data['text'],
      'type': data['type'] ?? 'multipleChoice',
      'options': data['options'] ?? [],
      'category': data['category'] ?? '',
      'topic': data['topic'] ?? '',
      'sequence': data['sequence'] ?? 9999,
      'course': data['course'],
      'minWords': data['minWords'] ?? 0,
      'maxWords': data['maxWords'] ?? 0,
    };

    final aData = <String, dynamic>{};
    if (isMcq) {
      aData['correctAnswerIndex'] = data['correctAnswerIndex'] ?? 0;
    } else {
      aData['correctAnswerTexts'] = data['correctAnswerTexts'] ?? [];
    }

    batch.set(newRef, qData);
    batch.set(_db.collection('answers').doc(newRef.id), aData);

    await batch.commit();
  }

  /// Update an existing question. Writes to both collections.
  Future<void> updateQuestion(String id, Map<String, dynamic> data) async {
    final batch = _db.batch();
    final qRef = _db.collection('questions').doc(id);
    final aRef = _db.collection('answers').doc(id);

    final isMcq = (data['type'] ?? 'multipleChoice') == 'multipleChoice';

    final qData = {
      'text': data['text'],
      'type': data['type'] ?? 'multipleChoice',
      'options': data['options'] ?? [],
      'category': data['category'] ?? '',
      'topic': data['topic'] ?? '',
      'sequence': data['sequence'] ?? 9999,
      'course': data['course'],
      'minWords': data['minWords'] ?? 0,
      'maxWords': data['maxWords'] ?? 0,
    };

    final aData = <String, dynamic>{};
    if (isMcq) {
      aData['correctAnswerIndex'] = data['correctAnswerIndex'] ?? 0;
      aData['correctAnswerTexts'] = FieldValue.delete(); // cleanup just in case
    } else {
      aData['correctAnswerTexts'] = data['correctAnswerTexts'] ?? [];
      aData['correctAnswerIndex'] = FieldValue.delete();
    }

    batch.update(qRef, qData);
    // Use set with merge in case the answers document doesn't exist yet
    batch.set(aRef, aData, SetOptions(merge: true));

    await batch.commit();
  }

  /// Delete a question. Removes from both collections.
  Future<void> deleteQuestion(String id) async {
    final batch = _db.batch();
    batch.delete(_db.collection('questions').doc(id));
    batch.delete(_db.collection('answers').doc(id));
    await batch.commit();
  }
}
