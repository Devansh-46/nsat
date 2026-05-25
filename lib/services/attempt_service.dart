import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attempt_model.dart';
import 'app_logger.dart';

/// The three outcomes of trying to start a test, so the caller can tell
/// them apart without relying on exceptions for normal flow.
enum StartAttemptOutcome {
  /// The lock was claimed — this student may now take the test.
  started,

  /// The student already finished a test. They are blocked.
  alreadyCompleted,

  /// The student has an unfinished attempt (likely an earlier crash).
  /// The caller may offer to contact an invigilator.
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
/// CRASH-SAFE DESIGN:
/// A bare "document exists" lock would permanently block a student whose
/// app died mid-test on flaky kiosk wifi. Instead the document carries a
/// `status`:
///   - `in_progress` — written when the test starts
///   - `completed`   — set by the scoreSubmission Cloud Function
/// "Already attempted" means status == completed, NOT mere existence.
///
/// SECURITY NOTE:
/// The Firestore rule for `attempts` allows:
///   - create: if true (status must be in_progress)
///   - update: if isAdmin() (only Cloud Functions / admin SDK)
/// This means the CLIENT can only ever CREATE a new attempt document.
/// It cannot update one. The transaction therefore only writes when
/// no document exists — if one exists (any status), it returns the
/// appropriate outcome without writing, which is safe under those rules.
class AttemptService {
  static const _tag = 'AttemptService';
  final _log = AppLogger.instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _collection = 'attempts';

  /// Attempts to claim the one-attempt lock for [applicationNo].
  ///
  /// Uses a transaction to prevent two devices racing to start the same test.
  ///
  /// Behaviour by existing document state:
  ///   - no document        → creates `in_progress`, returns [started]
  ///   - status completed   → returns [alreadyCompleted] (blocked)
  ///   - status in_progress → returns [resumable] (earlier unfinished run)
  ///
  /// IMPORTANT: The client Firestore rules only allow `create` on this
  /// collection, not `update`. So this method NEVER writes to an existing
  /// document — it only creates when no document exists. The Cloud Function
  /// (scoreSubmission) handles the completed status flip via admin SDK.
  Future<StartAttemptResult> startAttempt({
    required String applicationNo,
    required String testId,
  }) async {
    final reqId = AppLogger.generateRequestId();
    _log.info(_tag, 'Claiming attempt lock for $applicationNo (test: $testId)',
        requestId: reqId, persist: true);

    final docRef = _db.collection(_collection).doc(applicationNo);

    try {
      return await _db.runTransaction<StartAttemptResult>((txn) async {
        final snapshot = await txn.get(docRef);

        if (snapshot.exists) {
          final existing = AttemptModel.fromFirestore(snapshot);

          if (existing.isCompleted) {
            _log.info(_tag, 'Student $applicationNo already completed test',
                requestId: reqId, persist: true);
            return StartAttemptResult(
              StartAttemptOutcome.alreadyCompleted,
              attempt: existing,
            );
          }

          // in_progress: earlier session that didn't finish (app crash, etc.)
          _log.info(
              _tag, 'Resumable in-progress attempt found for $applicationNo',
              requestId: reqId, persist: true);
          return StartAttemptResult(
            StartAttemptOutcome.resumable,
            attempt: existing,
          );
        }

        // No document exists — create the lock.
        // This is a CREATE, which is allowed by Firestore rules.
        txn.set(docRef, {
          'status': AttemptModel.statusToString(AttemptStatus.inProgress),
          'attemptedAt': FieldValue.serverTimestamp(),
          'testId': testId,
        });

        _log.info(_tag, 'Attempt lock claimed for $applicationNo',
            requestId: reqId, persist: true);
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
    } on FirebaseException catch (e, st) {
      // PERMISSION_DENIED here means a document already exists and the
      // transaction tried to write — should never happen with the logic
      // above, but guard it explicitly so we don't surface a raw crash.
      if (e.code == 'permission-denied') {
        _log.error(
            _tag,
            'Permission denied claiming attempt for $applicationNo — '
            'document may already exist',
            error: e,
            stackTrace: st,
            requestId: reqId);
        // Re-read outside the transaction to return the correct outcome
        return _readAttemptOutcome(applicationNo, reqId);
      }
      _log.error(_tag, 'Firestore error claiming attempt for $applicationNo',
          error: e, stackTrace: st, requestId: reqId);
      return StartAttemptResult(
        StartAttemptOutcome.error,
        errorMessage: 'Could not start the test. Please check your '
            'connection and try again.',
      );
    } catch (e, st) {
      _log.error(_tag, 'Failed to claim attempt lock for $applicationNo',
          error: e, stackTrace: st, requestId: reqId);
      return StartAttemptResult(
        StartAttemptOutcome.error,
        errorMessage: 'Could not start the test. Please check your '
            'connection and try again.',
      );
    }
  }

  /// Reads the current attempt state and returns the appropriate outcome.
  /// Used as a fallback when a transaction is denied.
  Future<StartAttemptResult> _readAttemptOutcome(
      String applicationNo, String reqId) async {
    try {
      final doc = await _db.collection(_collection).doc(applicationNo).get();
      if (!doc.exists) {
        return StartAttemptResult(
          StartAttemptOutcome.error,
          errorMessage: 'Could not start the test. Please try again.',
        );
      }
      final existing = AttemptModel.fromFirestore(doc);
      if (existing.isCompleted) {
        _log.info(_tag, 'Fallback read: $applicationNo already completed',
            requestId: reqId, persist: true);
        return StartAttemptResult(
          StartAttemptOutcome.alreadyCompleted,
          attempt: existing,
        );
      }
      _log.info(_tag, 'Fallback read: $applicationNo has resumable attempt',
          requestId: reqId, persist: true);
      return StartAttemptResult(
        StartAttemptOutcome.resumable,
        attempt: existing,
      );
    } catch (e, st) {
      _log.error(_tag, 'Fallback read failed for $applicationNo',
          error: e, stackTrace: st, requestId: reqId);
      return StartAttemptResult(
        StartAttemptOutcome.error,
        errorMessage: 'Could not start the test. Please try again.',
      );
    }
  }

  /// Reads the current attempt for [applicationNo], or null if none exists.
  Future<AttemptModel?> getAttempt(String applicationNo) async {
    _log.debug(_tag, 'Checking existing attempt for $applicationNo');
    try {
      final doc = await _db.collection(_collection).doc(applicationNo).get();
      if (!doc.exists) return null;
      return AttemptModel.fromFirestore(doc);
    } catch (e, st) {
      _log.error(_tag, 'Failed to read attempt for $applicationNo',
          error: e, stackTrace: st);
      return null;
    }
  }
}
