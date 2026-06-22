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
      'ios_app_live': false,
      'android_app_live': true,
      'app_store_url': 'https://apps.apple.com/app/id6779738702',
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
  //
  // All getters are defensive: if the native Remote Config layer failed to
  // initialise (e.g. ensureInitialized timed out on iOS while waiting for an
  // App Check token), `_rc.getBool/getString/getInt` can throw. A throw here
  // would crash the build() of any widget reading config (e.g.
  // RoleSelectionScreen reads isMaintenanceMode), freezing the UI on the last
  // painted frame — the post-splash spinner. Falling back to the hardcoded
  // defaults keeps the app rendering no matter what.

  /// Whether students are allowed to start new tests right now.
  bool get isExamWindowOpen => _boolOr('exam_window_open', true);

  /// Whether the app is in maintenance mode (blocks student login).
  bool get isMaintenanceMode => _boolOr('maintenance_mode', false);

  /// Custom maintenance message from the Console.
  String get maintenanceMessage => _stringOr('maintenance_message',
      'NSAT is temporarily unavailable for scheduled maintenance. Please try again shortly.');

  /// Display date for the exam (shown on test category screen etc).
  String get examDateDisplay => _stringOr('exam_date_display', '14 June 2026');

  /// Returns the list of super admin emails allowed to view logs
  String get superAdminEmails =>
      _stringOr('super_admin_emails', 'devansh.chaubey@niu.edu.in');

  /// Minimum versionCode required. App below this must update.
  int get minVersionCode => _intOr('min_version_code', 1);

  /// Message shown on the force update screen.
  String get forceUpdateMessage => _stringOr('force_update_message',
      'A new version of NSAT is available with important updates. Please update to continue.');

  /// Play Store URL for the update button.
  String get playStoreUrl => _stringOr('play_store_url',
      'https://play.google.com/store/apps/details?id=in.edu.niu.nsat');

  /// True once the iOS app is live on the App Store. Default false =
  /// iOS users continue in the browser instead of hitting a dead listing.
  bool get isIosAppLive => _boolOr('ios_app_live', false);

  /// True while the Android app is live on the Play Store (default true).
  /// Flip to false from the Console to route Android users to web instead.
  bool get isAndroidAppLive => _boolOr('android_app_live', true);

  /// App Store URL for the iOS app (used only when isIosAppLive is true).
  String get appStoreUrl =>
      _stringOr('app_store_url', 'https://apps.apple.com/app/id6779738702');

  // ── Safe accessors ──

  bool _boolOr(String key, bool fallback) {
    try {
      return _rc.getBool(key);
    } catch (_) {
      return fallback;
    }
  }

  String _stringOr(String key, String fallback) {
    try {
      final v = _rc.getString(key);
      return v.isEmpty ? fallback : v;
    } catch (_) {
      return fallback;
    }
  }

  int _intOr(String key, int fallback) {
    try {
      return _rc.getInt(key);
    } catch (_) {
      return fallback;
    }
  }
  
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
