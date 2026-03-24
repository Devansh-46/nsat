import '../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Mock login endpoint
  Future<UserModel> login(String accsoftId, String password) async {
    await Future.delayed(const Duration(milliseconds: 1500)); // Simulate network

    if (accsoftId.isEmpty || password.isEmpty) {
      throw Exception('Credentials cannot be empty');
    }

    if (accsoftId == 'admin') {
      return UserModel(
        id: 'admin_1',
        accsoftId: 'admin',
        name: 'NIU Administrator',
        role: 'admin',
      );
    }

    // Accept anything else as student for testing
    return UserModel(
      id: 'student_1',
      accsoftId: accsoftId,
      name: 'John Doe',
      role: 'student',
    );
  }

  Future<void> saveUserSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accsoftId', user.accsoftId);
    await prefs.setString('role', user.role);
    await prefs.setString('name', user.name);
  }

  Future<UserModel?> getSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final accsoftId = prefs.getString('accsoftId');
    final role = prefs.getString('role');
    final name = prefs.getString('name');

    if (accsoftId != null && role != null) {
      return UserModel(
        id: '1',
        accsoftId: accsoftId,
        name: name ?? 'Student',
        role: role,
      );
    }
    return null;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
