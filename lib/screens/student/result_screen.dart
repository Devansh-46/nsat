import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../widgets/mesh_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/eyebrow.dart';
import '../../widgets/niu_button.dart';
import '../../widgets/note_box.dart';
import '../../providers/test_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/analytics_service.dart';

/// Result screen — calm, factual. Verdant Daylight reskin.
/// Score ring, stat grid, detail rows, disclaimer. No loud pass/fail.
class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _logged = false;

  void _logView(BuildContext context) {
    if (_logged) return;
    _logged = true;
    final auth = context.read<AuthProvider>();
    final testProvider = context.read<TestProvider>();
    final student = auth.verifiedStudent;
    if (student != null) {
      AnalyticsService.instance.logResultViewed(
        applicationNo: student.applicationNo,
        showResults: testProvider.showResults,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _logView(context);
    final testProvider = context.watch<TestProvider>();
    final session = testProvider.currentSession;
    final lead = context.watch<AuthProvider>().leadDetails;
    final showScores = testProvider.showResults;

    if (session == null) {
      return Scaffold(
        backgroundColor: AppColors.bgBase,
        body: MeshBackground(
          child: Center(
            child: Text('No test results found.',
                style: AppTheme.body(color: AppColors.ink3)),
          ),
        ),
      );
    }

    final pct = session.maxScore > 0
        ? (session.netScore / session.maxScore * 100)
        : 0.0;
    final pctText = '${pct.toStringAsFixed(1)}%';

    final submitted = session.submittedAt;
    final submittedText =
        submitted != null ? _formatDateTime(submitted) : '—';

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: MeshBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppColors.glassBgStrong,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Image.asset('assets/niu_crest.png', fit: BoxFit.contain),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Noida International University',
                            style: AppTheme.body(
                                size: 10.5, color: AppColors.ink4)),
                        Text('NSAT — Test Complete',
                            style: AppTheme.displaySm(size: 14)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                const Eyebrow('result'),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    text: 'Your test has been ',
                    style: AppTheme.display(size: 24),
                    children: [AppTheme.italicSpan('submitted.')],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  [
                    session.studentName,
                    if (lead != null) lead.courseKey.toUpperCase(),
                    session.studentId,
                  ].join('  ·  '),
                  style: AppTheme.mono(size: 11.5, color: AppColors.ink3),
                ),
                const SizedBox(height: 20),

                // ── Scores or withheld message ──
                if (showScores) ...[
                  // ── Score card ──
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        _ScoreRing(
                          fraction: session.maxScore > 0
                              ? (session.netScore / session.maxScore)
                                  .clamp(0.0, 1.0)
                              : 0.0,
                          centerTop: session.netScore.toStringAsFixed(
                              session.netScore % 1 == 0 ? 0 : 1),
                          centerBottom:
                              'of ${session.maxScore.toStringAsFixed(0)}',
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Eyebrow('score'),
                              const SizedBox(height: 4),
                              Text(
                                pctText,
                                style: AppTheme.mono(
                                    size: 28, color: AppColors.forest),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Net score after negative marking. '
                                'Your result has been recorded.',
                                style: AppTheme.body(
                                    size: 11.5, color: AppColors.ink3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Stat grid ──
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          icon: Icons.check,
                          tint: AppColors.forestTint,
                          iconColor: AppColors.forest,
                          value: '${session.correctCount}',
                          label: 'Correct',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.close,
                          tint: AppColors.clayTint,
                          iconColor: AppColors.clay,
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
                          tint: AppColors.bone,
                          iconColor: AppColors.ink4,
                          value: '${session.skippedCount}',
                          label: 'Skipped',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.task_alt,
                          tint: AppColors.forestTint,
                          iconColor: AppColors.forest,
                          value: '${session.answeredCount}',
                          label: 'Answered',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Detail rows ──
                  GlassCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    radius: 16,
                    child: Column(
                      children: [
                        _DetailRow(
                            label: 'Test', value: session.categoryName),
                        _divider(),
                        _DetailRow(
                            label: 'Total questions',
                            value: '${session.totalQuestions}'),
                        _divider(),
                        _DetailRow(
                          label: 'Marking',
                          value:
                              '+${session.marksPerQuestion.toStringAsFixed(0)} '
                              'correct · '
                              '-${session.negativeMarksPerWrong.toStringAsFixed(2)} '
                              'wrong',
                        ),
                        _divider(),
                        _DetailRow(
                            label: 'Submitted', value: submittedText),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Disclaimer ──
                  const NoteBox.gold(
                    icon: Icons.info_outline,
                    body: 'This is your test score only. Admission '
                        'decisions are made separately by the NIU '
                        'admissions team.',
                  ),
                ] else ...[
                  // ── Results withheld ──
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.forestTint,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.check_circle_outline,
                            size: 30,
                            color: AppColors.forest,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Thank you!',
                          style: AppTheme.display(
                              size: 22, color: AppColors.forest),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your answers have been recorded successfully. '
                          'Results for this test will be shared by the '
                          'NIU admissions team separately.',
                          textAlign: TextAlign.center,
                          style: AppTheme.body(
                              size: 13, color: AppColors.ink3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Minimal detail rows (no scores) ──
                  GlassCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    radius: 16,
                    child: Column(
                      children: [
                        _DetailRow(
                            label: 'Test', value: session.categoryName),
                        _divider(),
                        _DetailRow(
                            label: 'Questions attempted',
                            value: '${session.answeredCount} of ${session.totalQuestions}'),
                        _divider(),
                        _DetailRow(
                            label: 'Submitted', value: submittedText),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  const NoteBox.gold(
                    icon: Icons.info_outline,
                    body: 'Results will be communicated by the '
                        'NIU admissions office. Please check your '
                        'registered email for updates.',
                  ),
                ],
                const SizedBox(height: 20),

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
      ),
    );
  }

  static Widget _divider() =>
      Container(height: 0.5, color: AppColors.line2);

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

// ─── Score ring ─────────────────────────────────────────────────────

class _ScoreRing extends StatelessWidget {
  final double fraction;
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
      width: 100,
      height: 100,
      child: CustomPaint(
        painter: _RingPainter(fraction),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(centerTop,
                  style: AppTheme.mono(size: 26, color: AppColors.ink)),
              Text(centerBottom,
                  style: AppTheme.body(size: 10, color: AppColors.ink4)),
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
    const stroke = 8.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.bone;

    final progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = AppColors.forest;

    canvas.drawCircle(center, radius, track);
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

// ─── Stat tile ──────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final Color iconColor;
  final String value;
  final String label;

  const _StatTile({
    required this.icon,
    required this.tint,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      radius: 14,
      blurEnabled: false,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppTheme.mono(size: 18, color: AppColors.ink)),
              Text(label,
                  style: AppTheme.body(size: 10.5, color: AppColors.ink4)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Detail row ─────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTheme.body(size: 12.5, color: AppColors.ink4)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTheme.body(
                size: 12.5,
                color: AppColors.ink,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}