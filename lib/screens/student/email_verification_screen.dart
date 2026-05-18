import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/niu_app_bar.dart';
import '../../widgets/niu_button.dart';
import '../../providers/auth_provider.dart';

/// Step 2 of the NSAT login flow: email verification.
///
/// PHASE 1 / SPARK BUILD — this is a STUB.
/// The real flow (needs Blaze + Cloud Functions) is:
///   - live NPF API 2 call by lead_id -> registered email
///   - email shown masked for confirmation
///   - email OTP sent, entered, verified
///
/// None of that can run on Spark, so for the June 7 dry run this screen
/// just confirms the student and continues. The screen and its route
/// stay in place so the real OTP UI drops in here later with no
/// navigation changes.
class EmailVerificationScreen extends StatelessWidget {
  const EmailVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final student = context.watch<AuthProvider>().verifiedStudent;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const NiuAppBar(
            title: 'Email verification',
            subtitle: 'Confirm your identity',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Confirmed student card.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.bgGreenLight,
                      border: Border.all(color: AppColors.borderLight),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fee verified',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textGreen,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'NIU ID: ${student?.applicationNo ?? "-"}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stub notice — remove when real OTP is built.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.bgGoldLight,
                      border: Border.all(color: AppColors.borderGold),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Email OTP verification will appear here. It is not '
                      'active in this build — tap Continue to proceed to '
                      'your test.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textGold,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  NiuButton(
                    label: 'Continue',
                    onTap: () {
                      Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.testCategory,
                      );
                    },
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