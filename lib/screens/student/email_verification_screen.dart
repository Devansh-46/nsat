import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/niu_button.dart';
import '../../providers/auth_provider.dart';

/// Step 2 of the NSAT login flow: email verification.
///
/// PHASE 1 / SPARK BUILD — partial STUB.
/// On Continue this calls AuthProvider.fetchLeadDetails(), which on
/// Spark returns dev data and in production calls the NPF API 2 Cloud
/// Function. The real OTP UI (masked email, code entry) drops into this
/// screen later with no navigation change.
///
/// Visual design is consistent with the approved login / result screens
/// (pale-green page, white card, deep-forest green, gold accents).
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
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            children: [
              // --- Header ---
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.bgGreenLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  size: 28,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Verify your identity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'One quick check before your test begins.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 22),

              // --- Card ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fee-verified row.
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: AppColors.bgGreenLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Fee verified',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textGreen,
                                ),
                              ),
                              Text(
                                'NIU ID  ${student?.applicationNo ?? "-"}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stub notice.
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: AppColors.bgGoldLight,
                        border: Border.all(
                            color: AppColors.borderGold
                                .withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(Icons.lock_outline,
                              size: 16, color: AppColors.textGold),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Email OTP verification will appear '
                              'here. It is not active in this build '
                              '— tap Continue to proceed to your '
                              'test.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textGold,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

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
            ],
          ),
        ),
      ),
    );
  }
}