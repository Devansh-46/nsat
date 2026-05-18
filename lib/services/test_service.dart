import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/test_model.dart';

/// Reads from the `tests` Firestore collection.
///
/// The app only READS this collection. Test documents are created by the
/// project team directly in Phase 1 (admin app in Phase 2).
class TestService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _collection = 'tests';

  /// Returns the published test for a course, or null if none is live.
  ///
  /// [course] must be the canonical course key (e.g. "btech").
  ///
  /// If more than one published test exists for a course, the first is
  /// returned — Phase 1 assumes one published test per course.
  Future<TestModel?> getPublishedTestForCourse(String course) async {
    final snapshot = await _db
        .collection(_collection)
        .where('course', isEqualTo: course)
        .where('isPublished', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return TestModel.fromFirestore(snapshot.docs.first);
  }
}