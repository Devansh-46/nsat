import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/result_model.dart';
import '../models/app_log_model.dart';
import 'result_service.dart';
import 'app_logger.dart';

/// Admin-side data, backed by Firestore.
///
/// PHASE 1 SCOPE: results and test counts are real. "Online today" and
/// "CRM push failed" have no real data source on Spark, so they are not
/// reported here — the dashboard shows "—" for those. Notifications are
/// a separate screen, still pending the Blaze/FCM build.
class AdminService {
  static const _tag = 'AdminService';
  final _log = AppLogger.instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ResultService _resultService = ResultService();

  /// Dashboard summary numbers that CAN be real on Spark.
  ///
  /// Returns:
  ///   - totalAttempts : number of completed tests (results docs)
  ///   - activeTests   : number of published test documents
  Future<Map<String, int>> getDashboardStats() async {
    final reqId = AppLogger.generateRequestId();
    _log.debug(_tag, 'Fetching dashboard stats', requestId: reqId);

    try {
      final totalAttempts = await _resultService.resultsCount();

      final testsSnap = await _db
          .collection('tests')
          .where('isPublished', isEqualTo: true)
          .get();

      final stats = {
        'totalAttempts': totalAttempts,
        'activeTests': testsSnap.docs.length,
      };

      _log.info(_tag, 'Dashboard stats: $stats', requestId: reqId);
      return stats;
    } catch (e, st) {
      _log.error(_tag, 'Failed to fetch dashboard stats',
          error: e, stackTrace: st, requestId: reqId);
      rethrow;
    }
  }

  /// All results for the results dashboard, newest first.
  Future<List<ResultModel>> getAllResults() async {
    _log.debug(_tag, 'Fetching all results');
    try {
      final results = await _resultService.getAllResults();
      _log.info(_tag, 'Fetched ${results.length} results');
      return results;
    } catch (e, st) {
      _log.error(_tag, 'Failed to fetch results', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Fetches recent system logs from the app_logs collection.
  Future<List<AppLogModel>> fetchRecentLogs({int limit = 100}) async {
    final reqId = AppLogger.generateRequestId();
    _log.debug(_tag, 'Fetching recent logs', requestId: reqId);

    try {
      final snapshot = await _db
          .collection('app_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      final logs = snapshot.docs.map((doc) => AppLogModel.fromFirestore(doc)).toList();
      _log.info(_tag, 'Fetched ${logs.length} logs', requestId: reqId);
      return logs;
    } catch (e, st) {
      _log.error(_tag, 'Failed to fetch logs', error: e, stackTrace: st, requestId: reqId);
      rethrow;
    }
  }
}