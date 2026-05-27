import 'package:flutter/material.dart';
import '../models/result_model.dart';
import '../models/notification_model.dart';
import '../models/app_log_model.dart';
import '../services/admin_service.dart';
import '../services/admin_management_service.dart';
import '../services/notification_service.dart';
import '../services/app_logger.dart';

class AdminProvider extends ChangeNotifier {
  static const _tag = 'AdminProvider';
  final _log = AppLogger.instance;

  final AdminService _adminService = AdminService();
  final AdminManagementService _adminMgmtService = AdminManagementService();
  final NotificationService _notificationService = NotificationService();

  Map<String, int>? _dashboardStats;
  List<ResultModel> _allResults = [];
  List<NotificationModel> _notifications = [];
  List<AppLogModel> _logs = [];
  List<Map<String, dynamic>> _admins = [];
  List<String> _myCourses = ['*'];

  bool _isLoading = false;
  String? _error;
  String? _successMessage;

  Map<String, int>? get dashboardStats => _dashboardStats;
  List<ResultModel> get allResults => _allResults;
  List<NotificationModel> get notifications => _notifications;
  List<Map<String, dynamic>> get admins => _admins;
  List<String> get myCourses => _myCourses;
  List<AppLogModel> get logs => _logs;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;

  Future<void> fetchDashboardStats() async {
    _setLoading(true);
    try {
      _myCourses = await _adminService.getMyAllowedCourses();
      _dashboardStats = await _adminService.getDashboardStats(_myCourses);
    } catch (e, st) {
      _log.error(_tag, 'Failed to load dashboard stats', error: e, stackTrace: st);
      _error = 'Failed to load stats';
    }
    _setLoading(false);
  }

  Future<void> fetchAllResults() async {
    _setLoading(true);
    try {
      // Ensure we have courses loaded
      if (_myCourses.isEmpty) {
        _myCourses = await _adminService.getMyAllowedCourses();
      }
      _allResults = await _adminService.getAllResults(_myCourses);
      _log.debug(_tag, 'Loaded ${_allResults.length} results for courses: ${_myCourses.join(", ")}');
    } catch (e, st) {
      _log.error(_tag, 'Failed to load results', error: e, stackTrace: st);
      _error = 'Failed to load results';
    }
    _setLoading(false);
  }

  Future<void> fetchLogs() async {
    _setLoading(true);
    try {
      _logs = await _adminService.fetchRecentLogs();
    } catch (e, st) {
      _log.error(_tag, 'Failed to load system logs', error: e, stackTrace: st);
      _error = 'Failed to load system logs';
    }
    _setLoading(false);
  }

  // --- Admin management ---

  Future<void> fetchAdmins() async {
    _setLoading(true);
    try {
      _admins = await _adminMgmtService.listAdmins();
    } catch (e, st) {
      _log.error(_tag, 'Failed to load admins', error: e, stackTrace: st);
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    _setLoading(false);
  }

  Future<bool> addAdmin(String email) async {
    _setLoading(true);
    try {
      final role = await _adminMgmtService.addAdmin(email);
      _successMessage = 'Added $email as ${role == 'superAdmin' ? 'super admin' : 'admin'}';
      _log.info(_tag, 'Admin added: $email (role: $role)', persist: true);
      await fetchAdmins();
      _setLoading(false);
      return true;
    } catch (e, st) {
      _log.error(_tag, 'Failed to add admin: $email', error: e, stackTrace: st);
      _error = e.toString().replaceFirst('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> removeAdmin(String email) async {
    _setLoading(true);
    try {
      await _adminMgmtService.removeAdmin(email);
      _successMessage = 'Removed admin: $email';
      _log.info(_tag, 'Admin removed: $email', persist: true);
      await fetchAdmins();
      _setLoading(false);
      return true;
    } catch (e, st) {
      _log.error(_tag, 'Failed to remove admin: $email', error: e, stackTrace: st);
      _error = e.toString().replaceFirst('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateAdminCourses(String email, List<String> allowedCourses) async {
    _setLoading(true);
    try {
      await _adminMgmtService.updateAdminCourses(email, allowedCourses);
      _successMessage = 'Course access updated for $email';
      _log.info(_tag, 'Course access updated: $email → ${allowedCourses.join(", ")}', persist: true);
      await fetchAdmins();
      _setLoading(false);
      return true;
    } catch (e, st) {
      _log.error(_tag, 'Failed to update courses: $email', error: e, stackTrace: st);
      _error = e.toString().replaceFirst('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> promoteSuperadmin(String email) async {
    _setLoading(true);
    try {
      await _adminMgmtService.promoteSuperadmin(email);
      _successMessage = 'Promoted $email to super admin';
      _log.info(_tag, 'Promoted to superadmin: $email', persist: true);
      await fetchAdmins();
      _setLoading(false);
      return true;
    } catch (e, st) {
      _log.error(_tag, 'Failed to promote superadmin: $email', error: e, stackTrace: st);
      _error = e.toString().replaceFirst('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> demoteSuperadmin(String email) async {
    _setLoading(true);
    try {
      await _adminMgmtService.demoteSuperadmin(email);
      _successMessage = 'Demoted $email to admin';
      _log.info(_tag, 'Demoted from superadmin: $email', persist: true);
      await fetchAdmins();
      _setLoading(false);
      return true;
    } catch (e, st) {
      _log.error(_tag, 'Failed to demote superadmin: $email', error: e, stackTrace: st);
      _error = e.toString().replaceFirst('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  // --- Notifications ---

  Future<bool> sendNotification(
      String title, String body, String target, bool scheduleLater) async {
    _setLoading(true);
    try {
      final ok = await _notificationService.send(title, body, target);
      if (!ok) throw Exception('Send failed');
      _successMessage = 'Notification sent to ${target == "all" ? "all students" : target}';
      _log.info(_tag, 'Notification sent: target=$target, title="$title"', persist: true);
      await fetchNotifications();
      _setLoading(false);
      return true;
    } catch (e, st) {
      _log.error(_tag, 'Failed to send notification: target=$target',
          error: e, stackTrace: st);
      _error = 'Failed to send notification';
      _setLoading(false);
      return false;
    }
  }

  Future<void> fetchNotifications() async {
    try {
      _notifications = await _notificationService.getHistory();
      notifyListeners();
    } catch (e, st) {
      _log.error(_tag, 'Failed to load notification history', error: e, stackTrace: st);
    }
  }

  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    if (value) {
      _error = null;
      _successMessage = null;
    }
    notifyListeners();
  }
}
