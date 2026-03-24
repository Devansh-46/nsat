import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.role == 'admin';

  Future<void> initAuth() async {
    _isLoading = true;
    notifyListeners();

    _currentUser = await _authService.getSavedSession();

    _isLoading = false;
    notifyListeners();
  }

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
