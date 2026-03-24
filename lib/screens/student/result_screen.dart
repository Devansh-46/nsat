import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/niu_button.dart';
import '../../providers/test_provider.dart';
import '../../providers/auth_provider.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<TestProvider>().currentSession;
    final user = context.watch<AuthProvider>().currentUser;

    if (session == null) {
      return const Scaffold(
        body: Center(child: Text('No test results found.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Result header
            Container(
              width: double.infinity,
              color: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                children: [
                  const Text(
                    'Test submitted',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    session.formattedNetScore,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Net score out of ${session.formattedMaxScore}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.bgGoldLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${session.categoryName} — NIU-SAT',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textGold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Stats row
                    Row(
                      children: [
                        Expanded(
                            child: _StatBox(
                                value: '${session.correctCount}',
                                label: 'Correct',
                                color: AppColors.green)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _StatBox(
                                value: '${session.wrongCount}',
                                label: 'Wrong',
                                color: AppColors.red)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _StatBox(
                                value: '${session.skippedCount}',
                                label: 'Skipped',
                                color: AppColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Score breakdown
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          _ScoreRow(
                              label:
                                  'Correct (+${session.correctMarks.toStringAsFixed(2)})',
                              value:
                                  '+${session.correctMarks.toStringAsFixed(2)}',
                              color: AppColors.green),
                          const SizedBox(height: 5),
                          _ScoreRow(
                              label:
                                  'Wrong (${session.wrongCount} x -${session.negativeMarksPerWrong.toStringAsFixed(2)})',
                              value:
                                  '-${session.negativeMarks.toStringAsFixed(2)}',
                              color: AppColors.red),
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            height: 0.5,
                            color: AppColors.borderLight,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Net score',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                '${session.formattedNetScore} / ${session.formattedMaxScore}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Auto-sent notice
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: AppColors.bgGreenLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Your result has been saved and sent to NIU admissions automatically.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textGreen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    NiuButton(label: 'Download scorecard (PDF)'),
                    const SizedBox(height: 8),
                    NiuButton(
                      label:
                          'Download ${user?.course?.split(' ').first ?? 'course'} brochure',
                      variant: NiuButtonVariant.outline,
                    ),
                    const SizedBox(height: 16),
                    NiuButton(
                      label: 'Back to home',
                      variant: NiuButtonVariant.outline,
                      onTap: () {
                        context
                            .read<TestProvider>()
                            .clearSession(); // Clean up state
                        Navigator.popUntil(context,
                            ModalRoute.withName(AppRoutes.roleSelection));
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatBox({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ScoreRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        Text(value, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}
