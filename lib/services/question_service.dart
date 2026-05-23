import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/question_model.dart';
import 'app_logger.dart';

/// Reads from the `questions` Firestore collection.
///
/// SECURITY NOTE — read this before launch:
/// DATA_MODEL.md requires that the app never reads `correctAnswerIndex`,
/// and that scoring happens server-side. For the Phase 1 build on the
/// Spark plan there are no Cloud Functions, so:
///
///   - the `questions` security rule is TEMPORARILY `allow read: if true`
///   - this service reads the whole document, answer index included
///   - scoring is done by ScoringService locally
///
/// When Blaze is enabled, the re-secure step is isolated to ONE place:
/// change `_stripAnswers` below to `true`. That makes this service drop
/// `correctAnswerIndex` before it ever reaches the app, and ScoringService
/// switches to its Cloud Function path. Nothing else changes.
class QuestionService {
  static const _tag = 'QuestionService';
  final _log = AppLogger.instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _collection = 'questions';

  /// LAUNCH SWITCH: flip to `true` once scoring moves to a Cloud Function.
  /// While `false`, questions arrive with their answer index (Spark build).
  static const bool _stripAnswers = false;

  /// Fetches the questions for a course.
  ///
  /// [course] must be the canonical course key (e.g. "btech") — the same
  /// string stored in `questions.course` and `tests.course`.
  ///
  /// [limit] caps how many are returned. If the bank holds exactly the
  /// test's questionCount (as B.Tech does — 30 questions, count 30),
  /// every question is returned.
  Future<List<QuestionModel>> fetchQuestionsForCourse(
    String course,
    int limit,
  ) async {
    final reqId = AppLogger.generateRequestId();
    _log.debug(_tag, 'Fetching questions for course=$course, limit=$limit',
        requestId: reqId);

    try {
      final snapshot = await _db
          .collection(_collection)
          .where('course', isEqualTo: course)
          .limit(limit)
          .get();

      final questions = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        if (_stripAnswers) {
          data = Map<String, dynamic>.from(data);
          data['correctAnswerIndex'] = -1;
        }
        return QuestionModel.fromMap(data, id: doc.id);
      }).toList();

      // Sort so short answers are at the end, otherwise preserve order by ID
      questions.sort((a, b) {
        if (a.isShortAnswer && !b.isShortAnswer) return 1;
        if (!a.isShortAnswer && b.isShortAnswer) return -1;
        
        // If both are same type, sort by ID to match sequence (e.g. q1, q2)
        // Custom comparator needed since "q10" string-sorts before "q2"
        final aNumMatch = RegExp(r'\d+$').firstMatch(a.id);
        final bNumMatch = RegExp(r'\d+$').firstMatch(b.id);
        if (aNumMatch != null && bNumMatch != null) {
          final aNum = int.parse(aNumMatch.group(0)!);
          final bNum = int.parse(bNumMatch.group(0)!);
          return aNum.compareTo(bNum);
        }
        return a.id.compareTo(b.id);
      });

      _log.debug(_tag, 'Fetched ${questions.length} questions for $course',
          requestId: reqId);
      return questions;
    } catch (e, st) {
      _log.error(_tag, 'Failed to fetch questions for course=$course',
          error: e, stackTrace: st, requestId: reqId);
      rethrow;
    }
  }
}