import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/niu_app_bar.dart';
import '../../widgets/niu_button.dart';
import '../../providers/auth_provider.dart';

/// Step 1 of the NSAT login flow: the student enters their NIU ID,
/// and the app checks it against the synced `students` collection
/// (the fee gate).
///
/// What this screen does today:
///   - NIU ID entry
///   - Fee gate check via AuthProvider.checkNiuIdFeeGate()
///   - approved    -> go to the email-verification step (placeholder for now)
///   - notApproved -> show "Case 1" message
///   - notFound    -> show "Case 2" message
///   - error       -> show a network error with retry
///
/// NOT yet built (needs Cloud Functions / Blaze):
///   - live NPF email fetch, masked email confirm, email OTP.
class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  final TextEditingController _idController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    FocusScope.of(context).unfocus();
    final provider = context.read<AuthProvider>();

    final outcome =
        await provider.checkNiuIdFeeGate(_idController.text);

    if (!mounted) return;

    if (outcome == FeeGateOutcome.approved) {
      Navigator.pushNamed(context, AppRoutes.emailVerification);
    }
    // For every other outcome, the UI rebuilds and shows the
    // relevant message below (handled in build()).
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuthProvider>();
    final outcome = provider.lastFeeGateOutcome;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const NiuAppBar(
            title: 'Student login',
            subtitle: 'NIU ID verification',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter your NIU ID',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.primary),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _idController,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'e.g. NIU2025MBA0472',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                      onChanged: (_) {
                        // Editing the field clears any previous result.
                        if (provider.lastFeeGateOutcome != null) {
                          provider.resetFeeGate();
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Same as your application number.',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Loading spinner or the Continue button.
                  if (provider.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    NiuButton(
                      label: 'Continue',
                      onTap: _continue,
                    ),

                  const SizedBox(height: 16),

                  // --- Outcome messages ---
                  if (outcome == FeeGateOutcome.notApproved)
                    _MessageBox(
                      bg: AppColors.bgWarning,
                      border: AppColors.borderWarning,
                      titleColor: AppColors.textOrange,
                      title: "Your test access isn't active yet",
                      // TODO: confirm final wording + timing with director.
                      body:
                          'We found your NIU ID, but your application fee '
                          "hasn't been confirmed as paid yet.\n\n"
                          "If you've already paid, it can take some time to "
                          'reflect. Please check again later, or contact your '
                          'admission counsellor if it has been a while.',
                    ),

                  if (outcome == FeeGateOutcome.notFound)
                    _MessageBox(
                      bg: AppColors.bgRedLight,
                      border: AppColors.red,
                      titleColor: AppColors.textRed,
                      title: "We couldn't find this NIU ID",
                      // TODO: confirm final wording + contact details.
                      body:
                          'Please double-check the NIU ID you entered — it '
                          'should match your application number exactly.\n\n'
                          "If it's correct and you still see this, please "
                          'contact your admission counsellor for help.',
                    ),

                  if (outcome == FeeGateOutcome.error)
                    _MessageBox(
                      bg: AppColors.bgRedLight,
                      border: AppColors.red,
                      titleColor: AppColors.textRed,
                      title: 'Something went wrong',
                      body: provider.error ??
                          'Could not reach the server. Please check your '
                              'connection and try again.',
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

/// A simple coloured message box used for the fee-gate outcomes.
class _MessageBox extends StatelessWidget {
  final Color bg;
  final Color border;
  final Color titleColor;
  final String title;
  final String body;

  const _MessageBox({
    required this.bg,
    required this.border,
    required this.titleColor,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}