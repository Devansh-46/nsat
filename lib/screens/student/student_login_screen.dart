import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/mesh_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/eyebrow.dart';
import '../../widgets/niu_field.dart';
import '../../widgets/niu_button.dart';
import '../../widgets/note_box.dart';

/// Step 1 — NIU ID entry + fee gate.
///
/// Verdant Daylight redesign. Logic unchanged:
/// AuthProvider.checkNiuIdFeeGate → navigate to email verification.
class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  final _idController = TextEditingController();

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
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: MeshBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(22, topPad > 0 ? 12 : 28, 22, 32),
            child: Column(
              children: [
                // ── Brand header ──
                _buildCrest(),
                const SizedBox(height: 14),
                Text(
                  'Noida International University',
                  style: AppTheme.body(
                    size: 12.5,
                    color: AppColors.ink4,
                    weight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text('NSAT', style: AppTheme.display(size: 34)),
                const SizedBox(height: 2),
                Text(
                  'Student Aptitude Test',
                  style: AppTheme.body(size: 12, color: AppColors.ink4),
                ),
                const SizedBox(height: 28),

                // ── Welcome card ──
                GlassCard(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Eyebrow('candidate'),
                      const SizedBox(height: 6),
                      Text.rich(
                        TextSpan(
                          text: 'Welcome, ',
                          style: AppTheme.displaySm(size: 22),
                          children: [
                            AppTheme.italicSpan('applicant.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Enter your NIU ID to begin. We'll confirm "
                        'your details before the test.',
                        style: AppTheme.body(
                          size: 13.5,
                          color: AppColors.ink3,
                        ),
                      ),
                      const SizedBox(height: 22),

                      // NIU ID field
                      NiuField(
                        label: 'NIU ID',
                        hint: 'e.g. NIU2025BT0183',
                        icon: Icons.badge_outlined,
                        helper: 'Same as your application number',
                        errorText: _errorText(outcome),
                        controller: _idController,
                        textCapitalization: TextCapitalization.characters,
                        keyboardType: TextInputType.text,
                        onChanged: (_) {
                          if (provider.lastFeeGateOutcome != null) {
                            provider.resetFeeGate();
                          }
                        },
                        onSubmitted: (_) => _continue(),
                      ),
                      const SizedBox(height: 22),

                      // Continue button
                      if (provider.isLoading)
                        const SizedBox(
                          height: 48,
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
                        NiuButton(
                          label: 'Continue',
                          showArrow: true,
                          onTap: _continue,
                        ),

                      const SizedBox(height: 18),

                      // ── State note boxes ──
                      _buildNote(outcome, provider.error),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Step indicator ──
                _StepIndicator(current: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ──

  Widget _buildCrest() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: AppColors.glassBgStrong,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F2A1F),
            offset: Offset(0, 6),
            blurRadius: 18,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        'NIU',
        style: AppTheme.display(size: 22, color: AppColors.forest),
      ),
    );
  }

  /// Returns error text for the NiuField if the outcome warrants it,
  /// or null for the default / approved / loading states.
  String? _errorText(FeeGateOutcome? outcome) {
    switch (outcome) {
      case FeeGateOutcome.notFound:
        return 'NIU ID not found — check it matches your application number';
      case FeeGateOutcome.error:
        return 'Connection error — try again';
      default:
        return null;
    }
  }

  /// Builds the appropriate NoteBox for each state.
  Widget _buildNote(FeeGateOutcome? outcome, String? error) {
    if (outcome == null) {
      return const NoteBox.gold(
        icon: Icons.verified_user_outlined,
        title: 'Email verification next',
        body: "After your NIU ID, we'll verify a code sent to your "
            'registered email — keeping your attempt secure.',
      );
    }
    if (outcome == FeeGateOutcome.notApproved) {
      return const NoteBox.gold(
        icon: Icons.schedule,
        title: 'Payment pending',
        body: "We found your NIU ID, but your application fee hasn't "
            "been confirmed as paid yet. If you've already paid, "
            'please check again later or contact your admission counsellor.',
      );
    }
    if (outcome == FeeGateOutcome.notFound) {
      return const NoteBox.clay(
        icon: Icons.error_outline,
        body: 'We could not find this NIU ID. Please check it matches '
            'your application number exactly, or contact your admission '
            'counsellor.',
      );
    }
    if (outcome == FeeGateOutcome.error) {
      return NoteBox.clay(
        icon: Icons.cloud_off,
        body: error ??
            'Could not reach the server. Please check your connection '
                'and try again.',
      );
    }
    // approved — no note needed, screen navigates away
    return const SizedBox.shrink();
  }
}

// ─── Reusable step indicator ───────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  /// 0-based: 0 = ID, 1 = Email, 2 = Verify, 3 = Test.
  final int current;

  const _StepIndicator({this.current = 0});

  static const _labels = ['ID', 'Email', 'Verify', 'Test'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Dot row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final active = i == current;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 22 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: active ? AppColors.forest : AppColors.bone,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        // Label row
        Text.rich(
          TextSpan(
            style: AppTheme.body(size: 11.5, color: AppColors.ink4),
            children: [
              TextSpan(
                text: 'Step ${current + 1} of 4',
                style: AppTheme.body(
                  size: 11.5,
                  color: AppColors.ink3,
                  weight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: '  ·  '),
              for (int i = 0; i < _labels.length; i++) ...[
                if (i > 0) const TextSpan(text: '  ›  '),
                TextSpan(
                  text: _labels[i],
                  style: AppTheme.body(
                    size: 11.5,
                    color: i == current ? AppColors.forest : AppColors.ink4,
                    weight:
                        i == current ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}