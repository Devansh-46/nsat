import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'app_logger.dart';

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
  static const _tag = 'RemoteConfigService';
  final _log = AppLogger.instance;

  RemoteConfigService._();
  static final RemoteConfigService _instance = RemoteConfigService._();
  static RemoteConfigService get instance => _instance;

  final FirebaseRemoteConfig _rc = FirebaseRemoteConfig.instance;

  /// Initialize with defaults and fetch latest values.
  /// Call once at app startup (main.dart), after Firebase.initializeApp.
  Future<void> init() async {
    _log.debug(_tag, 'Initialising Remote Config');

    await _rc.ensureInitialized();

    await _rc.setDefaults({
      'exam_window_open': true,
      'maintenance_mode': false,
      'maintenance_message': 'NSAT is temporarily unavailable for scheduled maintenance. Please try again shortly.',
      'exam_date_display': '14 June 2026',
      'super_admin_emails': 'devansh.chaubey@niu.edu.in',
    });

    await _rc.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(minutes: 5),
    ));

    try {
      await _rc.fetchAndActivate();
      _log.info(_tag,
          'Remote Config fetched — exam_window=$isExamWindowOpen, '
          'maintenance=$isMaintenanceMode');
    } catch (e, st) {
      _log.error(_tag, 'Remote Config fetch failed, using defaults',
          error: e, stackTrace: st);
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

  /// Returns the list of super admin emails allowed to view logs
  String get superAdminEmails => _rc.getString('super_admin_emails');
  
  /// Helper to check if a specific email is a super admin
  bool isSuperAdmin(String email) {
    if (email.isEmpty) return false;
    final allowed = superAdminEmails.split(',').map((e) => e.trim().toLowerCase());
    return allowed.contains(email.toLowerCase());
  }

  /// Re-fetch latest config values. Call this if you want to
  /// force-refresh (e.g. from admin dashboard or on screen resume).
  Future<void> refresh() async {
    try {
      await _rc.fetchAndActivate();
      _log.debug(_tag, 'Remote Config refreshed');
    } catch (e, st) {
      _log.error(_tag, 'Remote Config refresh failed', error: e, stackTrace: st);
      // Keep current values
    }
  }
}
