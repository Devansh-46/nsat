import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/mesh_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/niu_button.dart';
import '../../widgets/note_box.dart';

/// Step 2 — Email verification (STUB in Phase 1 / Spark).
///
/// On Continue: AuthProvider.fetchLeadDetails() → test category.
/// Real OTP UI drops into this screen later with no nav change.
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
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: MeshBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(22, topPad > 0 ? 12 : 28, 22, 32),
            child: Column(
              children: [
                // ── Header icon ──
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: AppColors.glassBgStrong,
                    borderRadius: BorderRadius.circular(16),
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
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    size: 28,
                    color: AppColors.forest,
                  ),
                ),
                const SizedBox(height: 14),
                Text.rich(
                  TextSpan(
                    text: 'Verify your ',
                    style: AppTheme.displaySm(size: 22),
                    children: [AppTheme.italicSpan('identity.')],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'One quick check before your test begins.',
                  style: AppTheme.body(size: 12.5, color: AppColors.ink4),
                ),
                const SizedBox(height: 24),

                // ── Main card ──
                GlassCard(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fee-verified row
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.forestTint,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.forest.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                size: 18, color: AppColors.forest),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Fee verified',
                                    style: AppTheme.body(
                                      size: 12.5,
                                      color: AppColors.forest,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    'NIU ID  ${student?.applicationNo ?? "-"}',
                                    style: AppTheme.mono(
                                      size: 11.5,
                                      color: AppColors.ink3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // OTP stub note
                      const NoteBox.gold(
                        icon: Icons.lock_outline,
                        title: 'Email OTP — coming soon',
                        body: 'Email OTP verification will appear here. '
                            'It is not active in this build — tap '
                            'Continue to proceed to your test.',
                      ),
                      const SizedBox(height: 22),

                      // Continue
                      if (auth.isLoading)
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
                          onTap: () => _continue(context),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Step indicator (step 2) ──
                _StepIndicator(current: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Reuse the same step indicator from login (extracted as identical widget).
class _StepIndicator extends StatelessWidget {
  final int current;
  const _StepIndicator({this.current = 0});

  static const _labels = ['ID', 'Email', 'Verify', 'Test'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
                    weight: i == current ? FontWeight.w600 : FontWeight.w400,
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