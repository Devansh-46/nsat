import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/menu_row.dart';
import '../../widgets/stat_card.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              color: AppColors.primary,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'NIU-SAT Admin',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Good morning, Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dashboard grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2.0,
                      children: const [
                        StatCard(value: '234', label: 'Online today'),
                        StatCard(
                            value: '3',
                            label: 'Active tests',
                            valueColor: AppColors.green),
                        StatCard(value: '1,842', label: 'Total attempts'),
                        StatCard(
                            value: '12',
                            label: 'CRM push failed',
                            valueColor: AppColors.red),
                      ],
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Actions',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    MenuRow(
                      icon: Icons.add_box_outlined,
                      iconBgColor: AppColors.bgInfo,
                      iconColor: AppColors.primary,
                      title: 'Create new test',
                      subtitle: 'Set questions, timer, category',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.createTest),
                    ),
                    MenuRow(
                      icon: Icons.menu_book_outlined,
                      iconBgColor: AppColors.bgGoldLight,
                      iconColor: const Color(0xFF854F0B),
                      title: 'Question bank',
                      subtitle: 'Add / edit MCQ questions',
                    ),
                    MenuRow(
                      icon: Icons.show_chart,
                      iconBgColor: AppColors.bgGreenLight,
                      iconColor: const Color(0xFF27500A),
                      title: 'View results',
                      subtitle: 'All submissions + CRM logs',
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.resultsDashboard),
                    ),
                    MenuRow(
                      icon: Icons.notifications_outlined,
                      iconBgColor: AppColors.bgRedLight,
                      iconColor: const Color(0xFF791F1F),
                      title: 'Send notification',
                      subtitle: 'Push to all / filtered students',
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.pushNotification),
                    ),
                    MenuRow(
                      icon: Icons.search,
                      iconBgColor: AppColors.bgInfo,
                      iconColor: AppColors.primary,
                      title: 'Student lookup',
                      subtitle: 'Search by ACCSOFT ID',
                    ),

                    const SizedBox(height: 16),
                    // Logout button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.popUntil(
                            context,
                            ModalRoute.withName(AppRoutes.roleSelection)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.red,
                          side: const BorderSide(color: AppColors.red),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Logout',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
