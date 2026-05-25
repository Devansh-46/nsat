import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data_store.dart';
import 'app_logger.dart';

class AuthService {
  static const _tag = 'AuthService';
  final _log = AppLogger.instance;

  final DataStore _dataStore = DataStore();
  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<UserModel> studentLogin(String accsoftId) async {
    final reqId = AppLogger.generateRequestId();
    _log.debug(_tag, 'Student login attempt: $accsoftId', requestId: reqId);

    if (accsoftId.isEmpty) {
      _log.error(_tag, 'Empty ACCSOFT ID submitted', requestId: reqId);
      throw Exception('ACCSOFT ID cannot be empty');
    }

    final user = await _dataStore.getStudentByAccsoftId(accsoftId);
    if (user != null) {
      _log.info(_tag, 'Student login success: $accsoftId', requestId: reqId, persist: true);
      return user;
    } else {
      _log.error(_tag, 'Student not found: $accsoftId', requestId: reqId);
      throw Exception('Student not found in ACCSOFT records');
    }
  }

  Future<UserModel> adminLogin(String email, String password) async {
    final reqId = AppLogger.generateRequestId();
    _log.debug(_tag, 'Admin login attempt: $email', requestId: reqId);

    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        _log.error(_tag, 'Admin auth returned null user', requestId: reqId);
        throw Exception('Authentication failed');
      }

      final tokenResult = await credential.user!.getIdTokenResult(true);
      final isAdmin = tokenResult.claims?['admin'] == true;
      final isSuperAdmin = tokenResult.claims?['superAdmin'] == true;

      if (!isAdmin) {
        _log.error(_tag, 'Non-admin user attempted admin login: $email', requestId: reqId);
        await _firebaseAuth.signOut();
        throw Exception('Unauthorized: Admin access only');
      }

      // Check forcePasswordChange from Firestore (not claims — avoids token caching issues)
      bool forcePasswordChange = false;
      final adminDoc = await _db.collection('admins').doc(email.toLowerCase()).get();
      if (adminDoc.exists) {
        forcePasswordChange = (adminDoc.data()?['forcePasswordChange'] as bool?) ?? false;
      }

      _log.info(_tag, 'Admin login success: $email (superAdmin: $isSuperAdmin, forceChange: $forcePasswordChange)', requestId: reqId, persist: true);
      return UserModel(
        id: credential.user!.uid,
        accsoftId: 'admin',
        name: 'NIU Administrator',
        role: 'admin',
        isSuperAdmin: isSuperAdmin,
        forcePasswordChange: forcePasswordChange,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      _log.error(_tag, 'Admin login failed: ${e.code}', error: e, requestId: reqId);
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No admin account found with this email');
        case 'wrong-password':
          throw Exception('Incorrect password');
        case 'invalid-email':
          throw Exception('Invalid email format');
        case 'too-many-requests':
          throw Exception('Too many attempts. Please try again later');
        default:
          throw Exception('Login failed: ${e.message}');
      }
    }
  }

  Future<void> saveUserSession(UserModel user) async {
    _log.debug(_tag, 'Saving session for ${user.accsoftId}');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accsoftId', user.accsoftId);
    await prefs.setString('role', user.role);
    await prefs.setString('name', user.name);
    if (user.course != null) await prefs.setString('course', user.course!);
    await prefs.setBool('feePaid', user.feePaid);
    await prefs.setDouble('feeAmount', user.feeAmount);
    await prefs.setBool('hasAttempted', user.hasAttempted);
  }

  Future<UserModel?> getSavedSession() async {
    _log.debug(_tag, 'Restoring saved session');
    final prefs = await SharedPreferences.getInstance();
    final accsoftId = prefs.getString('accsoftId');
    final role = prefs.getString('role');
    final name = prefs.getString('name');

    if (accsoftId != null && role != null && name != null) {
      _log.info(_tag, 'Session restored for $accsoftId (role: $role)');
      return UserModel(
        id: role == 'admin' ? 'admin_1' : 'student_session',
        accsoftId: accsoftId,
        name: name,
        role: role,
        course: prefs.getString('course'),
        feePaid: prefs.getBool('feePaid') ?? false,
        feeAmount: prefs.getDouble('feeAmount') ?? 1100.0,
        hasAttempted: prefs.getBool('hasAttempted') ?? false,
      );
    }
    _log.debug(_tag, 'No saved session found');
    return null;
  }

  Future<void> clearSession() async {
    _log.info(_tag, 'Session cleared');
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _firebaseAuth.signOut();
  }
}
