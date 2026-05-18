import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/niu_app_bar.dart';
import '../../widgets/niu_button.dart';
import '../../widgets/info_row.dart';
import '../../providers/auth_provider.dart';

/// PLACEHOLDER screen.
///
/// In the finished flow this is where the app will:
///   1. fetch the student's registered email from NPF (via a Cloud Function),
///   2. show the masked email for the student to confirm,
///   3. send and verify an email OTP,
///   4. then show name / course / attempt status.
///
/// None of that is built yet — it needs Cloud Functions (Blaze plan).
/// For now this screen just confirms the fee gate passed and shows the
/// data we already have, so the flow has an honest stopping point.
class EmailVerificationScreen extends StatelessWidget {
  const EmailVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final student = context.read<AuthProvider>().verifiedStudent;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const NiuAppBar(
            title: 'Verify your email',
            subtitle: 'Step 2 of 4',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.bgGreenLight,
                      border: Border.all(color: AppColors.green),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: AppColors.green, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Application fee confirmed. Your NIU ID is '
                            'verified.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textGreen,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (student != null) ...[
                    const Text(
                      'From your record',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InfoRow(
                      dotColor: AppColors.primary,
                      label: 'NIU ID',
                      value: student.applicationNo,
                    ),
                    InfoRow(
                      dotColor: AppColors.green,
                      label: 'Fee status',
                      value: student.paymentStatus,
                    ),
                    const SizedBox(height: 8),
                  ],
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.bgInfo,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email verification — coming next',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'The next steps — fetching your registered email, '
                          'confirming it, and verifying a one-time code — '
                          'are still being built. They will appear here.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  NiuButton(
                    label: 'Back to home',
                    variant: NiuButtonVariant.outline,
                    onTap: () => Navigator.popUntil(
                      context,
                      ModalRoute.withName(AppRoutes.roleSelection),
                    ),
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
