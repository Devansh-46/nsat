import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/user_model.dart';
import '../models/student_model.dart';
import '../models/lead_details_model.dart';
import '../services/auth_service.dart';
import '../services/student_service.dart';
import '../services/app_logger.dart';

/// Outcome of the NIU ID fee-gate check, so the login screen
/// can show the right message for each case.
enum FeeGateOutcome {
  /// Fee approved — the student may proceed to the next step.
  approved,

  /// NIU ID was found but the fee is not approved (e.g. Payment Pending).
  notApproved,

  /// No student record exists for that NIU ID.
  notFound,

  /// Could not reach Firestore.
  error,
}

class AuthProvider extends ChangeNotifier {
  static const _tag = 'AuthProvider';
  final _log = AppLogger.instance;

  final AuthService _authService = AuthService();
  final StudentService _studentService = StudentService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  // --- NIU ID fee-gate flow ---
  StudentModel? _verifiedStudent;
  FeeGateOutcome? _lastFeeGateOutcome;

  /// Applicant detail from NPF API 2. Fetched live after the fee gate
  /// passes; held in memory for this session only, never stored.
  LeadDetailsModel? _leadDetails;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.role == 'admin';

  bool get isSuperAdmin {
    return _isSuperAdmin;
  }

  /// Set during admin login flow
  bool _isSuperAdmin = false;
  bool _forcePasswordChange = false;

  bool get forcePasswordChange => _forcePasswordChange;

  StudentModel? get verifiedStudent => _verifiedStudent;
  FeeGateOutcome? get lastFeeGateOutcome => _lastFeeGateOutcome;
  LeadDetailsModel? get leadDetails => _leadDetails;

  Future<void> initAuth() async {
    _isLoading = true;
    notifyListeners();

    _currentUser = await _authService.getSavedSession();

    if (_currentUser != null) {
      _log.setUserId(_currentUser!.accsoftId);
      _isSuperAdmin = _currentUser!.isSuperAdmin;
      _forcePasswordChange = _currentUser!.forcePasswordChange;
      _log.info(_tag, 'Auth restored for ${_currentUser!.accsoftId} (role: ${_currentUser!.role})');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Step 1 of the login flow — the fee gate.
  ///
  /// Looks the NIU ID up in the synced `students` collection and applies
  /// the fee gate. Returns a [FeeGateOutcome] the screen uses to decide
  /// what to show next.
  Future<FeeGateOutcome> checkNiuIdFeeGate(String niuId) async {
    final reqId = AppLogger.generateRequestId();
    _log.info(_tag, 'Fee gate check for NIU ID: $niuId',
        requestId: reqId, persist: true);

    _setLoading(true);
    _leadDetails = null; // clear any stale detail from a previous attempt

    final result = await _studentService.getStudentByNiuId(niuId);

    FeeGateOutcome outcome;
    switch (result.status) {
      case StudentLookupStatus.found:
        final student = result.student!;
        if (student.isFeeApproved) {
          _verifiedStudent = student;
          outcome = FeeGateOutcome.approved;
          _log.info(_tag, 'Fee gate APPROVED for $niuId',
              requestId: reqId, persist: true);
        } else {
          _verifiedStudent = null;
          outcome = FeeGateOutcome.notApproved;
          _log.info(_tag, 'Fee gate NOT APPROVED for $niuId',
              requestId: reqId, persist: true);
        }
        break;
      case StudentLookupStatus.notFound:
        _verifiedStudent = null;
        outcome = FeeGateOutcome.notFound;
        _log.info(_tag, 'Fee gate: student NOT FOUND: $niuId',
            requestId: reqId, persist: true);
        break;
      case StudentLookupStatus.error:
        _verifiedStudent = null;
        _error = result.errorMessage;
        outcome = FeeGateOutcome.error;
        _log.error(_tag, 'Fee gate check failed for $niuId: ${result.errorMessage}',
            requestId: reqId);
        break;
    }

    _lastFeeGateOutcome = outcome;
    _setLoading(false);
    return outcome;
  }

  /// Step 2 of the login flow — fetch the applicant's NPF detail.
  ///
  /// Calls the fetchLeadDetails Cloud Function with the verified
  /// student's lead_id. The function calls NPF API 2 and maps the
  /// course display string to the canonical key.
  Future<bool> fetchLeadDetails() async {
    if (_verifiedStudent == null) return false;

    final reqId = AppLogger.generateRequestId();
    _log.info(_tag, 'Fetching lead details for lead_id=${_verifiedStudent!.leadId}',
        requestId: reqId, persist: true);

    _setLoading(true);

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'asia-south1')
          .httpsCallable('fetchLeadDetails');

      final result = await callable.call<Map<String, dynamic>>({
        'lead_id': _verifiedStudent!.leadId,
      });

      final data = result.data;
      _leadDetails = LeadDetailsModel(
        leadId: data['leadId'] ?? _verifiedStudent!.leadId,
        name: data['name'] ?? '',
        courseKey: data['courseKey'] ?? '',
        email: data['email'] ?? '',
        mobile: data['mobile'] ?? '',
      );

      _log.info(_tag,
          'Lead details fetched: name=${_leadDetails!.name}, course=${_leadDetails!.courseKey}',
          requestId: reqId);

      _setLoading(false);
      return true;
    } catch (e, st) {
      _log.error(_tag, 'fetchLeadDetails Cloud Function failed',
          error: e, stackTrace: st, requestId: reqId);
      _error = 'Could not fetch your details. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  /// Clears the NIU ID flow state (e.g. when the user edits the field).
  void resetFeeGate() {
    _verifiedStudent = null;
    _lastFeeGateOutcome = null;
    _leadDetails = null;
    _error = null;
    notifyListeners();
  }

  // --- OLD CODE BELOW — kept intact for the admin path ---

  Future<bool> studentLogin(String accsoftId) async {
    _setLoading(true);
    try {
      final user = await _authService.studentLogin(accsoftId);
      _currentUser = user;
      _log.setUserId(accsoftId);
      await _authService.saveUserSession(user);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> adminLogin(String email, String password) async {
    _setLoading(true);
    try {
      final user = await _authService.adminLogin(email, password);
      _currentUser = user;
      _isSuperAdmin = user.isSuperAdmin;
      _forcePasswordChange = user.forcePasswordChange;
      _log.setUserId('admin');
      await _authService.saveUserSession(user);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  /// Change password and clear the forcePasswordChange flag in Firestore.
  Future<bool> changePassword(String newPassword) async {
    _setLoading(true);
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not signed in');

      await user.updatePassword(newPassword);

      // Clear forcePasswordChange in Firestore
      try {
        final email = user.email?.toLowerCase();
        if (email != null) {
          await FirebaseFirestore.instance
              .collection('admins')
              .doc(email)
              .update({'forcePasswordChange': false});
        }
      } catch (_) {
        // Non-critical: Firestore update failure shouldn't block login
      }

      // Also try to clear via CF (for claim-based checks)
      try {
        final callable = FirebaseFunctions.instanceFor(region: 'asia-south1')
            .httpsCallable('clearForcePasswordChange');
        await callable.call();
      } catch (_) {}

      _forcePasswordChange = false;
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(forcePasswordChange: false);
      }

      // Force token refresh so claims are up to date
      await user.getIdToken(true);

      _log.info(_tag, 'Password changed & flags cleared', persist: true);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _log.error(_tag, 'Failed to change password', error: e);
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    _log.info(_tag, 'User logout: ${_currentUser?.accsoftId}', persist: true);
    _log.clearUserId();
    await _authService.clearSession();
    _currentUser = null;
    _isSuperAdmin = false;
    _forcePasswordChange = false;
    _verifiedStudent = null;
    _lastFeeGateOutcome = null;
    _leadDetails = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    if (value) _error = null;
    notifyListeners();
  }
}