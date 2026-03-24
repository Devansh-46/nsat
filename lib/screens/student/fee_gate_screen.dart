import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/niu_app_bar.dart';
import '../../widgets/niu_button.dart';

import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class FeeGateScreen extends StatelessWidget {
  const FeeGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    final feeAmount = user?.feeAmount ?? 1100.0;
    final name = user?.name ?? 'Student';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          NiuAppBar(title: 'Access restricted', subtitle: name),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Warning box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.bgWarning,
                      border: Border.all(color: AppColors.borderWarning),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Application fee not paid',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textOrange,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your Rs.${feeAmount.toStringAsFixed(0)} application fee has not been received by NIU. Please complete payment to access the NIU-SAT.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'How to pay',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  _ContactRow(
                      icon: Icons.link, text: 'admissions.niu.edu.in/pay'),
                  _ContactRow(
                      icon: Icons.phone, text: '1800-XXX-XXXX (Admissions)'),
                  _ContactRow(
                      icon: Icons.email_outlined,
                      text: 'admissions@niu.edu.in'),

                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.bgGreenLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'After payment is processed, re-login with your ACCSOFT ID to access the test.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textGreen,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  NiuButton(
                    label: 'Back to home',
                    variant: NiuButtonVariant.outline,
                    onTap: () => Navigator.popUntil(
                        context, ModalRoute.withName(AppRoutes.roleSelection)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ContactRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.bgInfo,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
