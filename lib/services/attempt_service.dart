import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attempt_model.dart';

/// The three outcomes of trying to start a test, so the caller can tell
/// them apart without relying on exceptions for normal flow.
enum StartAttemptOutcome {
  /// The lock was claimed — this student may now take the test.
  started,

  /// The student already finished a test. They are blocked.
  alreadyCompleted,

  /// The student has an unfinished attempt (likely an earlier crash).
  /// The caller may offer to resume it.
  resumable,

  /// Something went wrong talking to Firestore.
  error,
}

class StartAttemptResult {
  final StartAttemptOutcome outcome;
  final AttemptModel? attempt;
  final String? errorMessage;

  StartAttemptResult(this.outcome, {this.attempt, this.errorMessage});
}

/// Reads and writes the `attempts` Firestore collection — the one-attempt
/// lock. Document ID = `application_no`.
///
/// CRASH-SAFE DESIGN (extends DATA_MODEL.md):
/// A bare "document exists" lock would permanently block a student whose
/// app died mid-test on flaky kiosk wifi. Instead the document carries a
/// `status`:
///   - `in_progress` — written transactionally when the test starts
///   - `completed`   — set when the result is saved
/// "Already attempted" means status == completed, NOT mere existence.
///
/// This collection is never touched by the NPF sync, so the 30-minute
/// `students` overwrite can never erase a lock.
class AttemptService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _collection = 'attempts';

  /// Attempts to claim the one-attempt lock for [applicationNo].
  ///
  /// Runs in a transaction so two devices cannot both start a test for
  /// the same NIU ID. Behaviour by existing state:
  ///   - no document       -> creates `in_progress`, returns `started`
  ///   - status completed  -> returns `alreadyCompleted` (blocked)
  ///   - status in_progress-> returns `resumable` (earlier unfinished run)
  Future<StartAttemptResult> startAttempt({
    required String applicationNo,
    required String testId,
  }) async {
    final docRef = _db.collection(_collection).doc(applicationNo);

    try {
      final result = await _db.runTransaction<StartAttemptResult>((txn) async {
        final snapshot = await txn.get(docRef);

        if (snapshot.exists) {
          final existing = AttemptModel.fromFirestore(snapshot);
          if (existing.isCompleted) {
            return StartAttemptResult(
              StartAttemptOutcome.alreadyCompleted,
              attempt: existing,
            );
          }
          // An in_progress doc already exists — do not overwrite it,
          // so the original attemptedAt / testId are preserved.
          return StartAttemptResult(
            StartAttemptOutcome.resumable,
            attempt: existing,
          );
        }

        // No attempt yet — claim the lock.
        txn.set(docRef, {
          'status': AttemptModel.statusToString(AttemptStatus.inProgress),
          'attemptedAt': FieldValue.serverTimestamp(),
          'testId': testId,
        });

        return StartAttemptResult(
          StartAttemptOutcome.started,
          attempt: AttemptModel(
            applicationNo: applicationNo,
            status: AttemptStatus.inProgress,
            testId: testId,
            attemptedAt: DateTime.now(),
          ),
        );
      });

      return result;
    } catch (e) {
      return StartAttemptResult(
        StartAttemptOutcome.error,
        errorMessage:
            'Could not start the test. Please check your connection '
            'and try again.',
      );
    }
  }

  /// Flips the attempt to `completed`. Called after the result is written.
  ///
  /// Uses merge so `attemptedAt` and `testId` from the start are kept.
  Future<void> markCompleted(String applicationNo) async {
    await _db.collection(_collection).doc(applicationNo).set(
      {
        'status': AttemptModel.statusToString(AttemptStatus.completed),
        'completedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Fast read used before login completes — does this student already
  /// have a finished attempt?
  Future<AttemptModel?> getAttempt(String applicationNo) async {
    final doc =
        await _db.collection(_collection).doc(applicationNo).get();
    if (!doc.exists) return null;
    return AttemptModel.fromFirestore(doc);
  }
}