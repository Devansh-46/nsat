import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/result_model.dart';

/// Reads and writes the `results` Firestore collection.
class ResultService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _collection = 'results';

  Future<String> saveResult(ResultModel result) async {
    final docRef = _db.collection(_collection).doc();
    await docRef.set({
      ...result.toMap(),
      'submittedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<List<ResultModel>> getAllResults() async {
    final snapshot = await _db
        .collection(_collection)
        .orderBy('submittedAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => ResultModel.fromFirestore(doc))
        .toList();
  }

  /// Total number of result documents (completed tests).
  ///
  /// FIXES Issue #40: Previously fetched ALL documents just to count them,
  /// which is slow and expensive at scale. Now uses Firestore's server-side
  /// count() aggregation query, which returns only the count — no documents
  /// are transferred.
  Future<int> resultsCount() async {
    final countQuery = await _db
        .collection(_collection)
        .count()
        .get();
    return countQuery.count ?? 0;
  }
}
