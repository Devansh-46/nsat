import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/test_model.dart';
import 'app_logger.dart';

/// Service for superadmin to manage test settings (publish, show results, etc.)
class TestManagementService {
  static const _tag = 'TestManagementService';
  final _log = AppLogger.instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _collection = 'tests';

  /// Fetches all tests regardless of published state.
  Future<List<TestModel>> getAllTests() async {
    final reqId = AppLogger.generateRequestId();
    try {
      final snapshot = await _db
          .collection(_collection)
          .orderBy('title')
          .get();
      final tests = snapshot.docs
          .map((doc) => TestModel.fromFirestore(doc))
          .toList();
      _log.info(_tag, 'Fetched ${tests.length} tests', requestId: reqId);
      return tests;
    } catch (e, st) {
      _log.error(_tag, 'Failed to fetch tests',
          error: e, stackTrace: st, requestId: reqId);
      rethrow;
    }
  }

  /// Updates specific fields on a test document.
  Future<void> updateTestFields(String testId, Map<String, dynamic> fields) async {
    final reqId = AppLogger.generateRequestId();
    try {
      await _db.collection(_collection).doc(testId).update(fields);
      _log.info(_tag, 'Updated test $testId: $fields',
          requestId: reqId, persist: true);
    } catch (e, st) {
      _log.error(_tag, 'Failed to update test $testId',
          error: e, stackTrace: st, requestId: reqId);
      rethrow;
    }
  }
}
