import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/student_model.dart';
import '../services/auth_service.dart';
import '../services/student_service.dart';

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
  final AuthService _authService = AuthService();
  final StudentService _studentService = StudentService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  // --- NEW: state for the NIU ID fee-gate flow ---
  StudentModel? _verifiedStudent;
  FeeGateOutcome? _lastFeeGateOutcome;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.role == 'admin';

  // --- NEW: getters for the fee-gate flow ---
  StudentModel? get verifiedStudent => _verifiedStudent;
  FeeGateOutcome? get lastFeeGateOutcome => _lastFeeGateOutcome;

  Future<void> initAuth() async {
    _isLoading = true;
    notifyListeners();

    _currentUser = await _authService.getSavedSession();

    _isLoading = false;
    notifyListeners();
  }

  /// NEW — Step 1 of the real login flow.
  ///
  /// Takes a NIU ID, looks it up in the synced `students` collection,
  /// and applies the fee gate. Returns a [FeeGateOutcome] the screen
  /// uses to decide what to show next.
  ///
  /// This does NOT yet do the email fetch / OTP steps — those need
  /// Cloud Functions and will be added later.
  Future<FeeGateOutcome> checkNiuIdFeeGate(String niuId) async {
    _setLoading(true);

    final result = await _studentService.getStudentByNiuId(niuId);

    FeeGateOutcome outcome;
    switch (result.status) {
      case StudentLookupStatus.found:
        final student = result.student!;
        if (student.isFeeApproved) {
          _verifiedStudent = student;
          outcome = FeeGateOutcome.approved;
        } else {
          _verifiedStudent = null;
          outcome = FeeGateOutcome.notApproved;
        }
        break;
      case StudentLookupStatus.notFound:
        _verifiedStudent = null;
        outcome = FeeGateOutcome.notFound;
        break;
      case StudentLookupStatus.error:
        _verifiedStudent = null;
        _error = result.errorMessage;
        outcome = FeeGateOutcome.error;
        break;
    }

    _lastFeeGateOutcome = outcome;
    _setLoading(false);
    return outcome;
  }

  /// Clears the NIU ID flow state (e.g. when the user edits the field).
  void resetFeeGate() {
    _verifiedStudent = null;
    _lastFeeGateOutcome = null;
    _error = null;
    notifyListeners();
  }

  // --- OLD CODE BELOW — kept intact until the new flow fully replaces it ---

  Future<bool> studentLogin(String accsoftId) async {
    _setLoading(true);
    try {
      final user = await _authService.studentLogin(accsoftId);
      _currentUser = user;
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
      await _authService.saveUserSession(user);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.clearSession();
    _currentUser = null;
    _verifiedStudent = null;
    _lastFeeGateOutcome = null;
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