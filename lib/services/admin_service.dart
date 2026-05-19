import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/result_model.dart';
import 'result_service.dart';

/// Admin-side data, backed by Firestore.
///
/// PHASE 1 SCOPE: results and test counts are real. "Online today" and
/// "CRM push failed" have no real data source on Spark, so they are not
/// reported here — the dashboard shows "—" for those. Notifications are
/// a separate screen, still pending the Blaze/FCM build.
class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ResultService _resultService = ResultService();

  /// Dashboard summary numbers that CAN be real on Spark.
  ///
  /// Returns:
  ///   - totalAttempts : number of completed tests (results docs)
  ///   - activeTests   : number of published test documents
  Future<Map<String, int>> getDashboardStats() async {
    final totalAttempts = await _resultService.resultsCount();

    final testsSnap = await _db
        .collection('tests')
        .where('isPublished', isEqualTo: true)
        .get();

    return {
      'totalAttempts': totalAttempts,
      'activeTests': testsSnap.docs.length,
    };
  }

  /// All results for the results dashboard, newest first.
  Future<List<ResultModel>> getAllResults() {
    return _resultService.getAllResults();
  }
}