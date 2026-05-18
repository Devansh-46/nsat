import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/niu_button.dart';
import '../../providers/test_provider.dart';
import '../../providers/auth_provider.dart';

/// Result screen — calm, factual. Shows the score ring, a stat grid,
/// the test detail rows, and a neutral disclaimer. No loud pass/fail
/// verdict. Follows the approved result mockup (deep forest theme).
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<TestProvider>().currentSession;
    final lead = context.watch<AuthProvider>().leadDetails;

    if (session == null) {
      return const Scaffold(
        backgroundColor: AppColors.bgLight,
        body: Center(child: Text('No test results found.')),
      );
    }

    // Percentage of the maximum score actually achieved.
    final pct = session.maxScore > 0
        ? (session.netScore / session.maxScore * 100)
        : 0.0;
    final pctText = '${pct.toStringAsFixed(1)}%';

    final submitted = session.submittedAt;
    final submittedText = submitted != null
        ? _formatDateTime(submitted)
        : '—';

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header ---
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'NIU',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Noida International University',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        'NSAT — Test Complete',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              const Text(
                'Your test has been submitted',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                [
                  session.studentName,
                  if (lead != null) lead.courseKey.toUpperCase(),
                  session.studentId,
                ].join('  ·  '),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // --- Score card: ring + percentage ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: _cardDecoration(),
                child: Row(
                  children: [
                    _ScoreRing(
                      // Ring fills by net score out of max.
                      fraction: session.maxScore > 0
                          ? (session.netScore / session.maxScore)
                              .clamp(0.0, 1.0)
                          : 0.0,
                      centerTop: session.netScore
                          .toStringAsFixed(
                              session.netScore % 1 == 0 ? 0 : 1),
                      centerBottom:
                          'of ${session.maxScore.toStringAsFixed(0)}',
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SCORE',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pctText,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Net score after negative marking. '
                            'Your result has been recorded.',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // --- Stat grid: correct / wrong / skipped / answered ---
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      icon: Icons.check,
                      iconBg: AppColors.bgGreenLight,
                      iconColor: AppColors.textGreen,
                      value: '${session.correctCount}',
                      label: 'Correct',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.close,
                      iconBg: AppColors.bgRedLight,
                      iconColor: AppColors.textRed,
                      value: '${session.wrongCount}',
                      label: 'Incorrect',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      icon: Icons.remove,
                      iconBg: AppColors.bgCard,
                      iconColor: AppColors.textMuted,
                      value: '${session.skippedCount}',
                      label: 'Skipped',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.task_alt,
                      iconBg: AppColors.bgInfo,
                      iconColor: AppColors.primary,
                      value: '${session.answeredCount}',
                      label: 'Answered',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // --- Detail rows ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 4),
                decoration: _cardDecoration(),
                child: Column(
                  children: [
                    _DetailRow(
                      label: 'Test',
                      value: session.categoryName,
                    ),
                    const _RowDivider(),
                    _DetailRow(
                      label: 'Total questions',
                      value: '${session.totalQuestions}',
                    ),
                    const _RowDivider(),
                    _DetailRow(
                      label: 'Marking',
                      value:
                          '+${session.marksPerQuestion.toStringAsFixed(0)} '
                          'correct · '
                          '-${session.negativeMarksPerWrong.toStringAsFixed(2)} '
                          'wrong',
                    ),
                    const _RowDivider(),
                    _DetailRow(
                      label: 'Submitted',
                      value: submittedText,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // --- Neutral disclaimer ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: AppColors.bgGoldLight,
                  border: Border.all(
                      color: AppColors.borderGold.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.info_outline,
                        size: 16, color: AppColors.textGold),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This is your test score only. Admission '
                        'decisions are made separately by the NIU '
                        'admissions team.',
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
              const SizedBox(height: 16),

              NiuButton(
                label: 'Back to home',
                variant: NiuButtonVariant.outline,
                onTap: () {
                  context.read<TestProvider>().clearSession();
                  Navigator.popUntil(context,
                      ModalRoute.withName(AppRoutes.roleSelection));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static String _formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$m $ampm';
  }
}

/// Circular score ring, drawn with a custom painter (no dependency).
class _ScoreRing extends StatelessWidget {
  final double fraction; // 0.0 .. 1.0
  final String centerTop;
  final String centerBottom;

  const _ScoreRing({
    required this.fraction,
    required this.centerTop,
    required this.centerBottom,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: CustomPaint(
        painter: _RingPainter(fraction),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerTop,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                centerBottom,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double fraction;
  _RingPainter(this.fraction);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 9.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.border;

    final progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = AppColors.primary;

    // Full track.
    canvas.drawCircle(center, radius, track);

    // Progress arc — starts at the top, sweeps clockwise.
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * fraction.clamp(0.0, 1.0),
      false,
      progress,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.fraction != fraction;
}

/// One stat tile in the result grid.
class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;

  const _StatTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 0.5, color: AppColors.borderLight);
  }
}