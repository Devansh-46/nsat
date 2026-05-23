import 'package:flutter/material.dart';
import '../models/result_model.dart';
import '../models/notification_model.dart';
import '../models/app_log_model.dart';
import '../services/admin_service.dart';
import '../services/notification_service.dart';
import '../services/app_logger.dart';

/// Admin-side state.
///
/// Results and dashboard stats are backed by real Firestore data.
/// Notifications remain on the mock NotificationService until the
/// Blaze/FCM Cloud Function is built — that screen is unchanged.
class AdminProvider extends ChangeNotifier {
  static const _tag = 'AdminProvider';
  final _log = AppLogger.instance;

  final AdminService _adminService = AdminService();
  final NotificationService _notificationService = NotificationService();

  Map<String, int>? _dashboardStats;
  List<ResultModel> _allResults = [];
  List<NotificationModel> _notifications = [];
  List<AppLogModel> _logs = [];

  bool _isLoading = false;
  String? _error;
  String? _successMessage;

  Map<String, int>? get dashboardStats => _dashboardStats;
  List<ResultModel> get allResults => _allResults;
  List<NotificationModel> get notifications => _notifications;
  List<AppLogModel> get logs => _logs;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;

  Future<void> fetchDashboardStats() async {
    _setLoading(true);
    try {
      _dashboardStats = await _adminService.getDashboardStats();
    } catch (e, st) {
      _log.error(_tag, 'Failed to load dashboard stats', error: e, stackTrace: st);
      _error = 'Failed to load stats';
    }
    _setLoading(false);
  }

  Future<void> fetchAllResults() async {
    _setLoading(true);
    try {
      _allResults = await _adminService.getAllResults();
      _log.debug(_tag, 'Loaded ${_allResults.length} results for dashboard');
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

  // --- Notifications: real FCM via Cloud Function ---

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
      // Silently fail history load.
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