import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../routes/app_routes.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Logo block
            const SizedBox(height: 32),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: const Text(
                'NIU\nSAT',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Noida International University',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Student Aptitude Test Portal',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),

            // Academic year banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      'Academic year',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '2025 — 26 Admissions',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Student login button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _RoleButton(
                label: 'Student login',
                subtitle: 'Login with your ACCSOFT ID',
                isPrimary: true,
                onTap: () => Navigator.pushNamed(context, AppRoutes.studentLogin),
              ),
            ),
            const SizedBox(height: 10),

            // Admin login button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _RoleButton(
                label: 'Admin login',
                subtitle: 'For NIU examination team',
                isPrimary: false,
                onTap: () => Navigator.pushNamed(context, AppRoutes.adminLogin),
              ),
            ),

            const Spacer(),
            const Text(
              'v1.0 — NIU IT Team',
              style: TextStyle(fontSize: 10, color: Color(0xFFBBBBBB)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool isPrimary;
  final VoidCallback? onTap;

  const _RoleButton({
    required this.label,
    required this.subtitle,
    required this.isPrimary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : const Color(0xFFF0F0F0),
          border: isPrimary ? null : Border.all(color: AppColors.primary),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isPrimary ? Colors.white : AppColors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isPrimary
                    ? Colors.white.withOpacity(0.8)
                    : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
