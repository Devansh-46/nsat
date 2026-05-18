import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/niu_button.dart';
import '../../providers/auth_provider.dart';

/// Step 1 of the NSAT login flow: NIU ID entry + fee gate.
///
/// Visual design follows the approved login mockup — pale green page,
/// a white welcome card, NIU-green primary action, gold security note,
/// and a step indicator. Logic is unchanged: AuthProvider.checkNiuIdFeeGate.
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
    final outcome = await provider.checkNiuIdFeeGate(_idController.text);
    if (!mounted) return;
    if (outcome == FeeGateOutcome.approved) {
      Navigator.pushNamed(context, AppRoutes.emailVerification);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuthProvider>();
    final outcome = provider.lastFeeGateOutcome;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
          child: Column(
            children: [
              // --- Brand header ---
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text(
                  'NIU',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Noida International University',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'NSAT',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Student Aptitude Test',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 24),

              // --- Welcome card ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
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
                    const Text(
                      'Welcome',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Enter your NIU ID to begin. We'll confirm "
                      'your details before the test.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),

                    const Text(
                      'NIU ID',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        border: Border.all(color: AppColors.primary),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(12, 0, 8, 0),
                            child: Icon(Icons.badge_outlined,
                                size: 18, color: AppColors.primary),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _idController,
                              textCapitalization:
                                  TextCapitalization.characters,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 14),
                                hintText: 'e.g. NIU2025MBA0472',
                                hintStyle: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              onChanged: (_) {
                                if (provider.lastFeeGateOutcome != null) {
                                  provider.resetFeeGate();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: const [
                        Icon(Icons.info_outline,
                            size: 13, color: AppColors.textMuted),
                        SizedBox(width: 4),
                        Text(
                          'Same as your application number',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    if (provider.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      NiuButton(label: 'Continue', onTap: _continue),

                    const SizedBox(height: 16),

                    // Security note (default state) OR outcome message.
                    if (outcome == null)
                      _NoteBox(
                        icon: Icons.verified_user_outlined,
                        bg: AppColors.bgGoldLight,
                        border: AppColors.borderGold,
                        iconColor: AppColors.textGold,
                        textColor: AppColors.textGold,
                        text:
                            "After your NIU ID, we'll verify a code sent "
                            'to your registered email — keeping your '
                            'attempt secure.',
                      ),

                    if (outcome == FeeGateOutcome.notApproved)
                      _NoteBox(
                        icon: Icons.schedule,
                        bg: AppColors.bgWarning,
                        border: AppColors.borderWarning,
                        iconColor: AppColors.textOrange,
                        textColor: AppColors.textOrange,
                        text:
                            "We found your NIU ID, but your application "
                            "fee hasn't been confirmed as paid yet. If "
                            "you've already paid, please check again "
                            'later or contact your admission counsellor.',
                      ),

                    if (outcome == FeeGateOutcome.notFound)
                      _NoteBox(
                        icon: Icons.error_outline,
                        bg: AppColors.bgRedLight,
                        border: AppColors.red,
                        iconColor: AppColors.textRed,
                        textColor: AppColors.textRed,
                        text:
                            'We could not find this NIU ID. Please check '
                            'it matches your application number exactly, '
                            'or contact your admission counsellor.',
                      ),

                    if (outcome == FeeGateOutcome.error)
                      _NoteBox(
                        icon: Icons.cloud_off,
                        bg: AppColors.bgRedLight,
                        border: AppColors.red,
                        iconColor: AppColors.textRed,
                        textColor: AppColors.textRed,
                        text: provider.error ??
                            'Could not reach the server. Please check '
                                'your connection and try again.',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // --- Step indicator ---
              const _StepIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

/// A coloured note / message box with a leading icon.
class _NoteBox extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color border;
  final Color iconColor;
  final Color textColor;
  final String text;

  const _NoteBox({
    required this.icon,
    required this.bg,
    required this.border,
    required this.iconColor,
    required this.textColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Step 1 of 4 · ID › Email › Verify › Test" progress indicator.
class _StepIndicator extends StatelessWidget {
  const _StepIndicator();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final active = i == 0;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 22 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        const Text(
          'Step 1 of 4  ·  ID  ›  Email  ›  Verify  ›  Test',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}