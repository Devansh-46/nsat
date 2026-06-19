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
  ///
  /// Defaults are applied first so the getters return sane values even if
  /// the network calls below hang or fail. On iOS, `ensureInitialized` and
  /// `fetchAndActivate` wait on an App Check token; with the debug Apple
  /// provider on a real device/TestFlight build that token can never be
  /// minted, so each network call is bounded by its own timeout to guarantee
  /// init() always returns and never blocks app startup.
  Future<void> init() async {
    _log.debug(_tag, 'Initialising Remote Config');

    // Apply defaults + settings FIRST. These are local/synchronous-ish and
    // ensure the getters work even if the network calls below never complete.
    await _rc.setDefaults({
      'exam_window_open': true,
      'maintenance_mode': false,
      'maintenance_message': 'NSAT is temporarily unavailable for scheduled maintenance. Please try again shortly.',
      'exam_date_display': '14 June 2026',
      'super_admin_emails': 'devansh.chaubey@niu.edu.in',
      'min_version_code': 1,
      'force_update_message': 'A new version of NSAT is available with important updates. Please update to continue.',
      'play_store_url': 'https://play.google.com/store/apps/details?id=in.edu.niu.nsat',
    });

    await _rc.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 6),
      minimumFetchInterval: const Duration(minutes: 5),
    ));

    // Bound ensureInitialized — on iOS it can stall on App Check.
    // Inner timeouts (4s + 6s) stay within the 10s cap the caller applies in
    // main.dart so each step can fail cleanly before the outer cap fires.
    try {
      await _rc.ensureInitialized().timeout(const Duration(seconds: 4));
    } catch (e, st) {
      _log.error(_tag, 'Remote Config ensureInitialized failed/timed out',
          error: e, stackTrace: st);
      // Defaults are already set above, so it is safe to continue.
    }

    try {
      // Defensive outer timeout: fetchTimeout governs the network call, but
      // the App Check token wait that precedes it is not covered by it.
      await _rc.fetchAndActivate().timeout(const Duration(seconds: 6));
      _log.info(_tag,
          'Remote Config fetched — exam_window=$isExamWindowOpen, '
          'maintenance=$isMaintenanceMode');
    } catch (e, st) {
      _log.error(_tag, 'Remote Config fetch failed/timed out, using defaults',
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

  /// Minimum versionCode required. App below this must update.
  int get minVersionCode => _rc.getInt('min_version_code');

  /// Message shown on the force update screen.
  String get forceUpdateMessage => _rc.getString('force_update_message');

  /// Play Store URL for the update button.
  String get playStoreUrl => _rc.getString('play_store_url');
  
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
