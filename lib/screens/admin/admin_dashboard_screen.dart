import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/mesh_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/eyebrow.dart';
import '../../widgets/niu_button.dart';

/// Admin dashboard — Verdant Daylight reskin. Real Firestore stats.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final admin = context.watch<AdminProvider>();
    final stats = admin.dashboardStats;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: MeshBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(22, topPad > 0 ? 12 : 24, 22, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow('dashboard'),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    text: 'Welcome, ',
                    style: AppTheme.display(size: 26),
                    children: [
                      AppTheme.italicSpan(
                        '${auth.currentUser?.name ?? "Admin"}.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Stats
                if (admin.isLoading && stats == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.forest,
                        ),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: '${stats?['totalAttempts'] ?? 0}',
                          label: 'Tests completed',
                          icon: Icons.task_alt,
                          tint: AppColors.forestTint,
                          iconColor: AppColors.forest,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          value: '${stats?['activeTests'] ?? 0}',
                          label: 'Published tests',
                          icon: Icons.assignment_outlined,
                          tint: AppColors.forestTint,
                          iconColor: AppColors.forest,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),

                const Eyebrow('quick actions'),
                const SizedBox(height: 10),

                _ActionCard(
                  icon: Icons.bar_chart_rounded,
                  tint: AppColors.forestTint,
                  iconColor: AppColors.forest,
                  title: 'View results',
                  subtitle: 'All student submissions',
                  onTap: () => Navigator.pushNamed(
                      context, AppRoutes.resultsDashboard),
                ),
                const SizedBox(height: 10),
                _ActionCard(
                  icon: Icons.notifications_outlined,
                  tint: AppColors.goldTint,
                  iconColor: const Color(0xFF8A6516),
                  title: 'Send notification',
                  subtitle: 'Push to students',
                  onTap: () {
                    admin.clearMessages();
                    Navigator.pushNamed(
                        context, AppRoutes.pushNotification);
                  },
                ),
                const SizedBox(height: 28),

                NiuButton(
                  label: 'Logout',
                  variant: NiuButtonVariant.outline,
                  onTap: () {
                    auth.logout();
                    Navigator.popUntil(context,
                        ModalRoute.withName(AppRoutes.roleSelection));
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color tint;
  final Color iconColor;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.tint,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      radius: 16,
      blurEnabled: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(value, style: AppTheme.mono(size: 26, color: AppColors.ink)),
          const SizedBox(height: 1),
          Text(label, style: AppTheme.body(size: 11.5, color: AppColors.ink4)),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.tint,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        radius: 16,
        blurEnabled: false,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.displaySm(size: 14)),
                  const SizedBox(height: 1),
                  Text(subtitle,
                      style: AppTheme.body(size: 11.5, color: AppColors.ink4)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.ink4),
          ],
        ),
      ),
    );
  }
}