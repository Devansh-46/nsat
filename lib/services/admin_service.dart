import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
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

  /// Get the allowed courses for the currently logged-in admin.
  /// Super admins get ["*"], regular admins get their assigned courses.
  Future<List<String>> getMyAllowedCourses() async {
    final email = firebase_auth.FirebaseAuth.instance.currentUser?.email?.toLowerCase();
    if (email == null) return [];

    // Check if super admin (from claim)
    final token = await firebase_auth.FirebaseAuth.instance.currentUser!.getIdTokenResult(true);
    if (token.claims?['superAdmin'] == true) {
      return ['*'];
    }

    // Regular admin — read from Firestore
    final doc = await _db.collection('admins').doc(email).get();
    if (!doc.exists) return [];
    return (doc.data()?['allowedCourses'] as List?)?.cast<String>() ?? [];
  }

  /// Dashboard stats filtered by allowed courses.
  Future<Map<String, int>> getDashboardStats(List<String> courses) async {
    final reqId = AppLogger.generateRequestId();

    try {
      final totalAttempts = await _resultService.getResultsCountByCourses(courses);

      // For published tests, also filter by courses if not wildcard
      int activeTests = 0;
      if (courses.contains('*')) {
        final testsSnap = await _db
            .collection('tests')
            .where('isPublished', isEqualTo: true)
            .get();
        activeTests = testsSnap.docs.length;
      } else {
        // Firestore doesn't support whereIn + count directly, so we query
        final testsSnap = await _db
            .collection('tests')
            .where('isPublished', isEqualTo: true)
            .where('course', whereIn: courses)
            .get();
        activeTests = testsSnap.docs.length;
      }

      final stats = {
        'totalAttempts': totalAttempts,
        'activeTests': activeTests,
      };

      _log.info(_tag, 'Dashboard stats (courses: ${courses.join(", ")}): $stats', requestId: reqId);
      return stats;
    } catch (e, st) {
      _log.error(_tag, 'Failed to fetch dashboard stats',
          error: e, stackTrace: st, requestId: reqId);
      rethrow;
    }
  }

  /// All results filtered by allowed courses.
  Future<List<ResultModel>> getAllResults(List<String> courses) async {
    _log.debug(_tag, 'Fetching results for courses: ${courses.join(", ")}');
    try {
      final results = await _resultService.getResultsByCourses(courses);
      _log.info(_tag, 'Fetched ${results.length} results for courses: ${courses.join(", ")}');
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