import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';
import 'app_logger.dart';

/// Result of a student lookup, so the caller can tell the three
/// outcomes apart without relying on exceptions for normal flow.
enum StudentLookupStatus {
  /// A matching student document was found.
  found,

  /// No document exists for that NIU ID.
  notFound,

  /// Something went wrong talking to Firestore (network, etc.).
  error,
}

class StudentLookupResult {
  final StudentLookupStatus status;
  final StudentModel? student;
  final String? errorMessage;

  StudentLookupResult(this.status, {this.student, this.errorMessage});
}

/// Reads from the `students` collection in Firestore.
///
/// This service ONLY reads. The `students` collection is written
/// exclusively by the NPF sync Cloud Function.
class StudentService {
  static const _tag = 'StudentService';
  final _log = AppLogger.instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _collection = 'students';

  /// Looks up a single student by their NIU ID (application number).
  ///
  /// The NIU ID is the Firestore document ID, so this is a fast,
  /// direct document read — not a query.
  Future<StudentLookupResult> getStudentByNiuId(String niuId) async {
    final trimmedId = niuId.trim();
    final reqId = AppLogger.generateRequestId();

    if (trimmedId.isEmpty) {
      _log.error(_tag, 'Empty NIU ID submitted', requestId: reqId);
      return StudentLookupResult(
        StudentLookupStatus.error,
        errorMessage: 'Please enter your NIU ID.',
      );
    }

    _log.debug(_tag, 'Looking up student: $trimmedId', requestId: reqId);

    try {
      final doc =
          await _db.collection(_collection).doc(trimmedId).get();

      if (!doc.exists) {
        _log.info(_tag, 'Student not found: $trimmedId', requestId: reqId, persist: true);
        return StudentLookupResult(StudentLookupStatus.notFound);
      }

      _log.info(_tag, 'Student found: $trimmedId', requestId: reqId);
      return StudentLookupResult(
        StudentLookupStatus.found,
        student: StudentModel.fromFirestore(doc),
      );
    } catch (e, st) {
      _log.error(_tag, 'Firestore read failed for student: $trimmedId',
          error: e, stackTrace: st, requestId: reqId);
      return StudentLookupResult(
        StudentLookupStatus.error,
        errorMessage:
            'Could not reach the server. Please check your connection '
            'and try again.',
      );
    }
  }
}