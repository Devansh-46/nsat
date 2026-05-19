import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/result_model.dart';

/// Reads and writes the `results` Firestore collection.
///
/// The student app creates its own result once on submission; the admin
/// app reads all results. Security rules allow create + read, not edit.
class ResultService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _collection = 'results';

  /// Writes a single result document and returns its generated ID.
  ///
  /// `submittedAt` is a server timestamp, so the time is the server's,
  /// not the (possibly wrong) device clock.
  Future<String> saveResult(ResultModel result) async {
    final docRef = _db.collection(_collection).doc();
    await docRef.set({
      ...result.toMap(),
      'submittedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Reads every result document, newest first. Used by the admin
  /// results dashboard.
  Future<List<ResultModel>> getAllResults() async {
    final snapshot = await _db
        .collection(_collection)
        .orderBy('submittedAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => ResultModel.fromFirestore(doc))
        .toList();
  }

  /// Total number of result documents (i.e. completed tests).
  Future<int> resultsCount() async {
    final snapshot = await _db.collection(_collection).get();
    return snapshot.docs.length;
  }
}