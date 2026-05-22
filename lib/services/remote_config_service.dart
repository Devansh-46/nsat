import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Centralized access to Firebase Remote Config values.
///
/// Controls exam-day switches from the Firebase Console without
/// deploying a new app version. Fetch + activate on app start,
/// then read values synchronously via the getters.
///
/// PARAMETERS (set in Firebase Console → Remote Config):
///   exam_window_open   (bool)   — true = students can start tests
///   maintenance_mode   (bool)   — true = block all student actions, show banner
///   maintenance_message (string) — custom text for the maintenance banner
///   exam_date_display  (string) — date shown on UI (e.g. "14 June 2026")
class RemoteConfigService {
  RemoteConfigService._();
  static final RemoteConfigService _instance = RemoteConfigService._();
  static RemoteConfigService get instance => _instance;

  final FirebaseRemoteConfig _rc = FirebaseRemoteConfig.instance;

  /// Initialize with defaults and fetch latest values.
  /// Call once at app startup (main.dart), after Firebase.initializeApp.
  Future<void> init() async {
    await _rc.ensureInitialized();

    await _rc.setDefaults({
      'exam_window_open': true,
      'maintenance_mode': false,
      'maintenance_message': 'NSAT is temporarily unavailable for scheduled maintenance. Please try again shortly.',
      'exam_date_display': '14 June 2026',
    });

    await _rc.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(minutes: 5),
    ));

    try {
      await _rc.fetchAndActivate();
    } catch (_) {
      // Silently use defaults if network is unavailable
    }
  }

  // ── Getters ──

  /// Whether students are allowed to start new tests right now.
  bool get isExamWindowOpen => _rc.getBool('exam_window_open');

  /// Whether the app is in maintenance mode (blocks student login).
  bool get isMaintenanceMode => _rc.getBool('maintenance_mode');

  /// Custom maintenance message from the Console.
  String get maintenanceMessage => _rc.getString('maintenance_message');

  /// Display date for the exam (shown on test category screen etc).
  String get examDateDisplay => _rc.getString('exam_date_display');

  /// Re-fetch latest config values. Call this if you want to
  /// force-refresh (e.g. from admin dashboard or on screen resume).
  Future<void> refresh() async {
    try {
      await _rc.fetchAndActivate();
    } catch (_) {
      // Keep current values
    }
  }
}
