import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'services/remote_config_service.dart';
import 'services/analytics_service.dart';
import 'services/app_logger.dart';
import 'services/fcm_service.dart';
import 'providers/auth_provider.dart';
import 'providers/test_provider.dart';
import 'providers/admin_provider.dart';
import 'theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'screens/student/role_selection_screen.dart';
import 'screens/student/student_login_screen.dart';
import 'screens/student/fee_gate_screen.dart';
import 'screens/student/test_category_screen.dart';
import 'screens/student/live_test_screen.dart';
import 'screens/student/result_screen.dart';
import 'screens/student/email_verification_screen.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/push_notification_screen.dart';
import 'screens/admin/results_dashboard_screen.dart';
import 'screens/admin/admin_logs_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- Structured logger setup ---
  final log = AppLogger.instance;
  log.init();

  // --- Crashlytics setup (mobile only — not supported on web) ---
  if (!kIsWeb) {
    // Catch Flutter framework errors (widget build failures, etc.)
    FlutterError.onError = (details) {
      log.error(
        'FlutterError',
        details.exceptionAsString(),
        error: details.exception,
        stackTrace: details.stack,
      );
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };

    // Catch async errors not handled by Flutter framework
    PlatformDispatcher.instance.onError = (error, stack) {
      log.error(
        'PlatformDispatcher',
        'Uncaught async error',
        error: error,
        stackTrace: stack,
      );
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  // --- Remote Config setup ---
  await RemoteConfigService.instance.init();

  // --- FCM setup — request permission and subscribe to broadcast topic
  // for every device on app open, regardless of course or login state.
  await FcmService().initializeForStudent('');

  log.info('Main', 'App startup complete', persist: true);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initAuth()),
        ChangeNotifierProvider(create: (_) => TestProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: const NiuSatApp(),
    ),
  );
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
        AppRoutes.liveTest: (_) => const LiveTestScreen(),
        AppRoutes.result: (_) => const ResultScreen(),
        AppRoutes.adminLogin: (_) => const AdminLoginScreen(),
        AppRoutes.adminDashboard: (_) => const AdminDashboardScreen(),
        AppRoutes.pushNotification: (_) => const PushNotificationScreen(),
        AppRoutes.resultsDashboard: (_) => const ResultsDashboardScreen(),
        AppRoutes.adminLogs: (_) => const AdminLogsScreen(),
      },
    );
  }
}