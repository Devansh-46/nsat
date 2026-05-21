import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data_store.dart';

class AuthService {
  final DataStore _dataStore = DataStore();
  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;

  Future<UserModel> studentLogin(String accsoftId) async {
    if (accsoftId.isEmpty) {
      throw Exception('ACCSOFT ID cannot be empty');
    }

    final user = await _dataStore.getStudentByAccsoftId(accsoftId);
    if (user != null) {
      return user;
    } else {
      throw Exception('Student not found in ACCSOFT records');
    }
  }

  Future<UserModel> adminLogin(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Authentication failed');
      }

      final tokenResult = await credential.user!.getIdTokenResult(true);
      final isAdmin = tokenResult.claims?['admin'] == true;

      if (!isAdmin) {
        await _firebaseAuth.signOut();
        throw Exception('Unauthorized: Admin access only');
      }

      return UserModel(
        id: credential.user!.uid,
        accsoftId: 'admin',
        name: 'NIU Administrator',
        role: 'admin',
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
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
    final prefs = await SharedPreferences.getInstance();
    final accsoftId = prefs.getString('accsoftId');
    final role = prefs.getString('role');
    final name = prefs.getString('name');

    if (accsoftId != null && role != null && name != null) {
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
    return null;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _firebaseAuth.signOut();
  }
}
