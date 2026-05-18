import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/niu_app_bar.dart';
import '../../widgets/niu_button.dart';
import '../../providers/auth_provider.dart';

/// Step 2 of the NSAT login flow: email verification.
///
/// PHASE 1 / SPARK BUILD — partial STUB.
/// On Continue this calls AuthProvider.fetchLeadDetails(), which on
/// Spark returns dev data and in production calls the NPF API 2 Cloud
/// Function. The real OTP UI (masked email, code entry) drops into this
/// screen later with no navigation change.
class EmailVerificationScreen extends StatelessWidget {
  const EmailVerificationScreen({super.key});

  Future<void> _continue(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.fetchLeadDetails();
    if (!context.mounted) return;

    if (ok) {
      Navigator.pushReplacementNamed(context, AppRoutes.testCategory);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Could not fetch details.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final student = auth.verifiedStudent;

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

                  if (auth.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    NiuButton(
                      label: 'Continue',
                      onTap: () => _continue(context),
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