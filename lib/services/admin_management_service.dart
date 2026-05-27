import 'package:cloud_functions/cloud_functions.dart';
import 'app_logger.dart';

/// Calls Cloud Functions to manage admin users and list admins.
class AdminManagementService {
  static const _tag = 'AdminManagementService';
  final _log = AppLogger.instance;

  /// Grant admin access to a user by email.
  /// If the email is in the superadmin allowlist, they become a superadmin.
  /// Otherwise they become a regular admin (added to Firestore).
  Future<String> addAdmin(String email) async {
    final reqId = AppLogger.generateRequestId();
    _log.info(_tag, 'Adding admin: $email', requestId: reqId, persist: true);

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'asia-south1')
          .httpsCallable('setAdminClaim');
      final result = await callable.call({'email': email});
      final data = result.data as Map<String, dynamic>;
      final role = data['role'] as String? ?? 'admin';
      _log.info(_tag, 'Admin added: $email (role: $role)', requestId: reqId, persist: true);
      return role;
    } on FirebaseFunctionsException catch (e) {
      _log.error(_tag, 'Failed to add admin: $email — ${e.code}: ${e.message}',
          error: e, requestId: reqId);
      throw Exception(_mapCfError(e));
    } catch (e, st) {
      _log.error(_tag, 'Failed to add admin: $email', error: e, stackTrace: st, requestId: reqId);
      throw Exception('Failed to add admin. Please try again.');
    }
  }

  /// Revoke admin access from a user.
  Future<void> removeAdmin(String email) async {
    final reqId = AppLogger.generateRequestId();
    _log.info(_tag, 'Removing admin: $email', requestId: reqId, persist: true);

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'asia-south1')
          .httpsCallable('removeAdminClaim');
      await callable.call({'email': email});
      _log.info(_tag, 'Admin removed: $email', requestId: reqId, persist: true);
    } on FirebaseFunctionsException catch (e) {
      _log.error(_tag, 'Failed to remove admin: $email — ${e.code}: ${e.message}',
          error: e, requestId: reqId);
      throw Exception(_mapCfError(e));
    } catch (e, st) {
      _log.error(_tag, 'Failed to remove admin: $email', error: e, stackTrace: st, requestId: reqId);
      throw Exception('Failed to remove admin. Please try again.');
    }
  }

  /// List all admins (superadmins from .env + regular admins from Firestore).
  Future<List<Map<String, dynamic>>> listAdmins() async {
    final reqId = AppLogger.generateRequestId();
    _log.debug(_tag, 'Listing admins', requestId: reqId);

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'asia-south1')
          .httpsCallable('listAdmins');
      final result = await callable.call();
      final data = result.data as Map<String, dynamic>;
      final admins = (data['admins'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _log.info(_tag, 'Listed ${admins.length} admins', requestId: reqId);
      return admins;
    } on FirebaseFunctionsException catch (e) {
      _log.error(_tag, 'Failed to list admins — ${e.code}: ${e.message}',
          error: e, requestId: reqId);
      throw Exception(_mapCfError(e));
    } catch (e, st) {
      _log.error(_tag, 'Failed to list admins', error: e, stackTrace: st, requestId: reqId);
      throw Exception('Failed to load admin list.');
    }
  }

  /// Promote an existing admin to superadmin.
  Future<void> promoteSuperadmin(String email) async {
    final reqId = AppLogger.generateRequestId();
    _log.info(_tag, 'Promoting to superadmin: $email', requestId: reqId, persist: true);

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'asia-south1')
          .httpsCallable('promoteSuperadmin');
      await callable.call({'email': email});
      _log.info(_tag, 'Promoted to superadmin: $email', requestId: reqId, persist: true);
    } on FirebaseFunctionsException catch (e) {
      _log.error(_tag, 'Failed to promote superadmin: $email — ${e.code}: ${e.message}',
          error: e, requestId: reqId);
      throw Exception(_mapCfError(e));
    } catch (e, st) {
      _log.error(_tag, 'Failed to promote superadmin: $email', error: e, stackTrace: st, requestId: reqId);
      throw Exception('Failed to promote to superadmin. Please try again.');
    }
  }

  /// Demote a superadmin back to regular admin.
  Future<void> demoteSuperadmin(String email) async {
    final reqId = AppLogger.generateRequestId();
    _log.info(_tag, 'Demoting from superadmin: $email', requestId: reqId, persist: true);

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'asia-south1')
          .httpsCallable('demoteSuperadmin');
      await callable.call({'email': email});
      _log.info(_tag, 'Demoted from superadmin: $email', requestId: reqId, persist: true);
    } on FirebaseFunctionsException catch (e) {
      _log.error(_tag, 'Failed to demote superadmin: $email — ${e.code}: ${e.message}',
          error: e, requestId: reqId);
      throw Exception(_mapCfError(e));
    } catch (e, st) {
      _log.error(_tag, 'Failed to demote superadmin: $email', error: e, stackTrace: st, requestId: reqId);
      throw Exception('Failed to demote from superadmin. Please try again.');
    }
  }

  /// Update the allowed courses for an admin.
  Future<void> updateAdminCourses(String email, List<String> allowedCourses) async {
    final reqId = AppLogger.generateRequestId();
    _log.info(_tag, 'Updating courses for $email: ${allowedCourses.join(", ")}',
        requestId: reqId, persist: true);

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'asia-south1')
          .httpsCallable('updateAdminCourses');
      await callable.call({
        'email': email,
        'allowedCourses': allowedCourses,
      });
      _log.info(_tag, 'Courses updated for $email', requestId: reqId, persist: true);
    } on FirebaseFunctionsException catch (e) {
      _log.error(_tag, 'Failed to update courses: ${e.code}: ${e.message}',
          error: e, requestId: reqId);
      throw Exception(_mapCfError(e));
    } catch (e, st) {
      _log.error(_tag, 'Failed to update courses', error: e, stackTrace: st, requestId: reqId);
      throw Exception('Failed to update course access.');
    }
  }

  String _mapCfError(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unauthenticated':
        return 'Authentication required. Sign in again.';
      case 'permission-denied':
        return e.message ?? 'Permission denied.';
      case 'invalid-argument':
        return e.message ?? 'Invalid input.';
      case 'not-found':
        return e.message ?? 'User not found.';
      default:
        return e.message ?? 'Something went wrong.';
    }
  }
}
