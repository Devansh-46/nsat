import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'screens/student/role_selection_screen.dart';
import 'screens/student/student_login_screen.dart';
import 'screens/student/fee_gate_screen.dart';
import 'screens/student/test_category_screen.dart';
import 'screens/student/live_test_screen.dart';
import 'screens/student/result_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/create_test_screen.dart';
import 'screens/admin/push_notification_screen.dart';
import 'screens/admin/results_dashboard_screen.dart';

void main() {
  runApp(const NiuSatApp());
}

class NiuSatApp extends StatelessWidget {
  const NiuSatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NIU-SAT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.roleSelection,
      routes: {
        AppRoutes.roleSelection: (_) => const RoleSelectionScreen(),
        AppRoutes.studentLogin: (_) => const StudentLoginScreen(),
        AppRoutes.feeGate: (_) => const FeeGateScreen(),
        AppRoutes.testCategory: (_) => const TestCategoryScreen(),
        AppRoutes.liveTest: (_) => const LiveTestScreen(),
        AppRoutes.result: (_) => const ResultScreen(),
        AppRoutes.adminDashboard: (_) => const AdminDashboardScreen(),
        AppRoutes.createTest: (_) => const CreateTestScreen(),
        AppRoutes.pushNotification: (_) => const PushNotificationScreen(),
        AppRoutes.resultsDashboard: (_) => const ResultsDashboardScreen(),
      },
    );
  }
}
