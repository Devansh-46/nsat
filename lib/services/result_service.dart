import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/result_model.dart';

/// Writes to the `results` Firestore collection.
///
/// One document per completed test. The app creates its own result once,
/// on submission. Security rules allow create-own but not edit-others'.
class ResultService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _collection = 'results';

  /// Writes a single result document and returns its generated ID.
  ///
  /// `submittedAt` is set with a server timestamp so the time is the
  /// server's, not the (possibly wrong) device clock.
  Future<String> saveResult(ResultModel result) async {
    final docRef = _db.collection(_collection).doc();
    await docRef.set({
      ...result.toMap(),
      'submittedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }
}