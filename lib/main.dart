import 'dart:async';
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
import 'theme/app_colors.dart';
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
import 'screens/admin/manage_admins_screen.dart';
import 'screens/admin/course_access_screen.dart';
import 'screens/admin/change_password_screen.dart';
import 'widgets/splash_screen.dart';

final _log = AppLogger.instance;

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      _log.error('Main', 'Firebase init failed', error: e);
    }

    _log.init();

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

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    try {
      await RemoteConfigService.instance.init();
    } catch (e) {
      _log.error('Main', 'RemoteConfig init failed', error: e);
    }

    try {
      await FcmService().initializeForStudent('');
    } catch (e) {
      _log.error('Main', 'FCM init failed', error: e);
    }

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
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
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
