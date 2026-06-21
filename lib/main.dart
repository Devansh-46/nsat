import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:window_manager/window_manager.dart';
import 'firebase_options.dart';
import 'services/remote_config_service.dart';
import 'services/analytics_service.dart';
import 'services/app_logger.dart';
import 'services/fcm_service.dart';
import 'providers/auth_provider.dart';
import 'providers/test_provider.dart';
import 'providers/admin_provider.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'screens/student/role_selection_screen.dart';
import 'screens/student/student_login_screen.dart';
import 'screens/student/fee_gate_screen.dart';
import 'screens/student/test_category_screen.dart';
import 'screens/student/rules_screen.dart';
import 'screens/student/live_test_screen.dart';
import 'screens/student/result_screen.dart';
import 'screens/student/email_verification_screen.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/push_notification_screen.dart';
import 'screens/admin/results_dashboard_screen.dart';
import 'screens/admin/admin_logs_screen.dart';
import 'screens/admin/manage_admins_screen.dart';
import 'screens/admin/course_access_screen.dart';
import 'screens/admin/change_password_screen.dart';
import 'screens/admin/test_settings_screen.dart';
import 'screens/force_update_screen.dart';
import 'utils/version_check.dart';
import 'widgets/splash_screen.dart';

final _log = AppLogger.instance;

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      await windowManager.ensureInitialized();
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // App Check — ensures requests come from the genuine NSAT app.
      //
      // iOS: release builds use App Attest (real device attestation); debug
      // builds keep the debug provider because App Attest cannot run in the
      // Simulator or without provisioning. Requires the App Attest entitlement
      // (ios/Runner/Runner.entitlements) and the App Attest provider registered
      // in Firebase Console → App Check for this iOS app.
      //
      // Backend currently soft-enforces (consumeAppCheckToken, not
      // enforceAppCheck), so a missing/invalid token never blocks requests —
      // it only weakens the anti-abuse signal until enforcement is turned on.
      //
      // Android stays on the debug provider for now; switch to
      // AndroidProvider.playIntegrity once Play Integrity is configured. Web
      // still needs a real reCAPTCHA Enterprise site key below before web
      // App Check produces valid tokens.
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider:
            kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
        webProvider: ReCaptchaEnterpriseProvider('YOUR_RECAPTCHA_SITE_KEY'),
      );
    } catch (e) {
      _log.error('Main', 'Firebase init failed', error: e);
    }

    _log.init();

    // TEMP DIAGNOSTIC (remove once the post-splash black-screen is fixed):
    // In release builds a thrown widget renders as a blank/black screen with no
    // detail. This paints the actual exception on screen so a device we can't
    // attach a debugger to can still tell us what failed during build.
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        color: const Color(0xFFF4EFE3),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                const Text('Something went wrong rendering this screen',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B2E2E))),
                const SizedBox(height: 12),
                Text(details.exceptionAsString(),
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF5A4A3A))),
              ],
            ),
          ),
        ),
      );
    };

    if (!kIsWeb) {
      FlutterError.onError = (details) {
        _log.error(
          'FlutterError',
          details.exceptionAsString(),
          error: details.exception,
          stackTrace: details.stack,
        );
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        _log.error(
          'PlatformDispatcher',
          'Uncaught async error',
          error: error,
          stackTrace: stack,
        );
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }

    runApp(const AppRoot());
  }, (error, stack) {
    _log.error('Zone', 'Uncaught zone error', error: error, stackTrace: stack);
  });
}

class NiuSatApp extends StatelessWidget {
  const NiuSatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NSAT',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [AnalyticsService.instance.observer],
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.roleSelection,
      routes: {
        AppRoutes.roleSelection: (_) => const RoleSelectionScreen(),
        AppRoutes.studentLogin: (_) => const StudentLoginScreen(),
        AppRoutes.emailVerification: (_) => const EmailVerificationScreen(),
        AppRoutes.feeGate: (_) => const FeeGateScreen(),
        AppRoutes.testCategory: (_) => const TestCategoryScreen(),
        AppRoutes.rules: (_) => const RulesScreen(),
        AppRoutes.liveTest: (_) => const LiveTestScreen(),
        AppRoutes.result: (_) => const ResultScreen(),
        AppRoutes.adminLogin: (_) => const AdminLoginScreen(),
        AppRoutes.adminDashboard: (_) => const AdminDashboardScreen(),
        AppRoutes.pushNotification: (_) => const PushNotificationScreen(),
        AppRoutes.resultsDashboard: (_) => const ResultsDashboardScreen(),
        AppRoutes.adminLogs: (_) => const AdminLogsScreen(),
        AppRoutes.manageAdmins: (_) => const ManageAdminsScreen(),
        AppRoutes.courseAccess: (_) => const CourseAccessScreen(),
        AppRoutes.changePassword: (_) => const ChangePasswordScreen(),
        AppRoutes.testSettings: (_) => const TestSettingsScreen(),
      },
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _splashDone = false;
  bool _servicesReady = false;
  bool _updateRequired = false;

  // On-screen diagnostics: shows which init stage we're on (and any caught
  // error) under the post-splash spinner. If startup ever hangs on a device
  // we can't attach a debugger to, the screen tells us exactly where.
  String _stage = 'Starting…';
  String? _stageError;

  void _setStage(String s, [String? err]) {
    if (mounted) {
      setState(() {
        _stage = s;
        _stageError = err;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    // Absolute safety net: no matter what happens below, force the app to
    // proceed after this deadline so it can never sit on the spinner forever.
    Timer(const Duration(seconds: 18), () {
      if (mounted && !_servicesReady) {
        _log.error('Main', 'Init watchdog fired — forcing app to proceed');
        setState(() => _servicesReady = true);
      }
    });

    _setStage('Loading config…');
    try {
      await RemoteConfigService.instance
          .init()
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      _log.error('Main', 'RemoteConfig init failed or timed out', error: e);
      _setStage('Config skipped', e.toString());
    }

    // Check if force update is needed
    _setStage('Checking version…', _stageError);
    try {
      _updateRequired = await VersionCheck.isUpdateRequired()
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      _log.error('Main', 'Version check failed or timed out', error: e);
      _setStage('Version check skipped', e.toString());
    }

    // FCM init must NOT block app startup. On iOS/TestFlight, subscribeToTopic
    // waits for an APNs token, which can hang indefinitely (no timeout in the
    // SDK) — leaving the app stuck on the post-splash spinner (blank screen).
    // Fire-and-forget with a timeout so the UI proceeds regardless.
    unawaited(
      FcmService()
          .initializeForStudent('')
          .timeout(const Duration(seconds: 8))
          .catchError((e) {
        _log.error('Main', 'FCM init failed or timed out', error: e);
      }),
    );

    _setStage('Finishing…', _stageError);
    if (mounted) {
      setState(() => _servicesReady = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_splashDone) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.bgBase,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.forest,
            brightness: Brightness.light,
          ).copyWith(surface: AppColors.bgBase),
        ),
        home: SplashScreen(
          onComplete: () => setState(() => _splashDone = true),
        ),
      );
    }

    if (!_servicesReady) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.bgBase,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.forest,
            brightness: Brightness.light,
          ).copyWith(surface: AppColors.bgBase),
        ),
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(
                  _stage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.ink4),
                ),
                if (_stageError != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 10, 32, 0),
                    child: Text(
                      _stageError!,
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.ink5),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    if (_updateRequired) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const ForceUpdateScreen(),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initAuth()),
        ChangeNotifierProvider(create: (_) => TestProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: const NiuSatApp(),
    );
  }
}
