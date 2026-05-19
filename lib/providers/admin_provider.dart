import 'package:flutter/material.dart';
import '../models/result_model.dart';
import '../models/notification_model.dart';
import '../services/admin_service.dart';
import '../services/notification_service.dart';

/// Admin-side state.
///
/// Results and dashboard stats are backed by real Firestore data.
/// Notifications remain on the mock NotificationService until the
/// Blaze/FCM Cloud Function is built — that screen is unchanged.
class AdminProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();
  final NotificationService _notificationService = NotificationService();

  Map<String, int>? _dashboardStats;
  List<ResultModel> _allResults = [];
  List<NotificationModel> _notifications = [];

  bool _isLoading = false;
  String? _error;
  String? _successMessage;

  Map<String, int>? get dashboardStats => _dashboardStats;
  List<ResultModel> get allResults => _allResults;
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;

  Future<void> fetchDashboardStats() async {
    _setLoading(true);
    try {
      _dashboardStats = await _adminService.getDashboardStats();
    } catch (e) {
      _error = 'Failed to load stats';
    }
    _setLoading(false);
  }

  Future<void> fetchAllResults() async {
    _setLoading(true);
    try {
      _allResults = await _adminService.getAllResults();
    } catch (e) {
      _error = 'Failed to load results';
    }
    _setLoading(false);
  }

  // --- Notifications: unchanged, still mock until Blaze/FCM ---

  Future<bool> sendNotification(
      String title, String body, String category, bool scheduleLater) async {
    _setLoading(true);
    try {
      await _notificationService.sendPushNotification(
        title: title,
        body: body,
        category: category,
        scheduleLater: scheduleLater,
      );
      _successMessage = scheduleLater
          ? 'Notification scheduled successfully'
          : 'Notification pushed successfully';
      await fetchNotifications();
      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Failed to send notification';
      _setLoading(false);
      return false;
    }
  }

  Future<void> fetchNotifications() async {
    try {
      _notifications = await _notificationService.getHistory();
      notifyListeners();
    } catch (e) {
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