import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../models/result_model.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/eyebrow.dart';
import '../../widgets/mesh_background.dart';
import '../../widgets/note_box.dart';

/// Admin result detail screen — a full report card for one student's submission.
/// Shows score breakdown, stat grid, marking scheme, and short answer responses.
class ResultDetailScreen extends StatelessWidget {
  final ResultModel result;

  const ResultDetailScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final pct = result.maxScore > 0
        ? (result.netScore / result.maxScore * 100)
        : 0.0;

    final submittedText = result.submittedAt != null
        ? DateFormat('d MMM yyyy, h:mm a').format(result.submittedAt!)
        : '—';

    final hasShortAnswers = result.shortAnswerResponses.isNotEmpty;

    // Sort short answer keys numerically
    final sortedKeys = result.shortAnswerResponses.keys.toList()
      ..sort((a, b) {
        final ai = int.tryParse(a) ?? 0;
        final bi = int.tryParse(b) ?? 0;
        return ai.compareTo(bi);
      });

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: MeshBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(22, topPad > 0 ? 8 : 20, 22, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.bone,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.chevron_left,
                            size: 20, color: AppColors.ink3),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Eyebrow('report card'),
                          Text(
                            result.studentName.isEmpty
                                ? '(no name)'
                                : result.studentName,
                            style: AppTheme.displaySm(size: 18),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // ── Identity card ──
                GlassCard(
                  padding: const EdgeInsets.all(18),
                  radius: 18,
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.forestTint,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.person_outline,
                            size: 24, color: AppColors.forest),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              result.studentName.isEmpty
                                  ? '(no name)'
                                  : result.studentName,
                              style: AppTheme.body(
                                size: 14,
                                color: AppColors.ink,
                                weight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${result.applicationNo}  ·  ${result.course.toUpperCase()}',
                              style: AppTheme.mono(
                                  size: 11, color: AppColors.ink4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── Score ring + percent ──
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      _ScoreRing(
                        fraction: result.maxScore > 0
                            ? (result.netScore / result.maxScore)
                                .clamp(0.0, 1.0)
                            : 0.0,
                        centerTop: result.netScore.toStringAsFixed(
                            result.netScore % 1 == 0 ? 0 : 1),
                        centerBottom:
                            'of ${result.maxScore.toStringAsFixed(0)}',
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Eyebrow('net score'),
                            const SizedBox(height: 4),
                            Text(
                              '${pct.toStringAsFixed(1)}%',
                              style: AppTheme.mono(
                                  size: 28, color: AppColors.forest),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'After negative marking applied.',
                              style: AppTheme.body(
                                  size: 11.5, color: AppColors.ink3),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              submittedText,
                              style: AppTheme.mono(
                                  size: 11, color: AppColors.ink4),
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
                        value: '${result.correctCount}',
                        label: 'Correct',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.close,
                        tint: AppColors.clayTint,
                        iconColor: AppColors.clay,
                        value: '${result.wrongCount}',
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
                        value: '${result.skippedCount}',
                        label: 'Skipped',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.assignment_outlined,
                        tint: AppColors.goldTint,
                        iconColor: const Color(0xFF8A6516),
                        value:
                            '${result.correctCount + result.wrongCount + result.skippedCount}',
                        label: 'Total MCQs',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Test detail rows ──
                GlassCard(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  radius: 16,
                  child: Column(
                    children: [
                      _DetailRow(
                          label: 'Test', value: result.testId),
                      _divider(),
                      _DetailRow(
                          label: 'Course',
                          value: result.course.toUpperCase()),
                      _divider(),
                      _DetailRow(
                          label: 'NIU ID', value: result.applicationNo),
                      _divider(),
                      _DetailRow(
                          label: 'Net score',
                          value:
                              '${result.netScore.toStringAsFixed(2)} / ${result.maxScore.toStringAsFixed(0)}'),
                      _divider(),
                      _DetailRow(
                          label: 'Submitted', value: submittedText),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Short answers section ──
                if (hasShortAnswers) ...[
                  const Eyebrow('short answer responses'),
                  const SizedBox(height: 8),
                  const NoteBox.gold(
                    icon: Icons.info_outline,
                    body:
                        'These are descriptive responses — not graded automatically. Review manually.',
                  ),
                  const SizedBox(height: 12),
                  ...sortedKeys.asMap().entries.map((entry) {
                    final displayIndex = entry.key + 1;
                    final key = entry.value;
                    final response =
                        result.shortAnswerResponses[key] ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ShortAnswerCard(
                        questionNumber: displayIndex,
                        response: response,
                      ),
                    );
                  }),
                ] else ...[
                  GlassCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 20),
                    radius: 16,
                    child: Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline,
                            size: 18, color: AppColors.ink4),
                        const SizedBox(width: 12),
                        Text(
                          'No short answer responses recorded.',
                          style: AppTheme.body(
                              size: 13, color: AppColors.ink4),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _divider() =>
      Container(height: 0.5, color: AppColors.line2);
}

// ─── Short answer card ───────────────────────────────────────────────

class _ShortAnswerCard extends StatefulWidget {
  final int questionNumber;
  final String response;

  const _ShortAnswerCard({
    required this.questionNumber,
    required this.response,
  });

  @override
  State<_ShortAnswerCard> createState() => _ShortAnswerCardState();
}

class _ShortAnswerCardState extends State<_ShortAnswerCard> {
  bool _expanded = true;

  int get _wordCount {
    final t = widget.response.trim();
    if (t.isEmpty) return 0;
    return t.split(RegExp(r'\s+')).length;
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = widget.response.trim().isEmpty;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.forestTint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${widget.questionNumber}',
                    style: AppTheme.mono(
                        size: 12, color: AppColors.forest),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Short Answer Q${widget.questionNumber}',
                    style: AppTheme.body(
                      size: 13.5,
                      color: AppColors.ink,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
                // Word count badge
                if (!isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.bone,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$_wordCount w',
                      style: AppTheme.mono(
                          size: 10, color: AppColors.ink4),
                    ),
                  ),
                const SizedBox(width: 6),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 18,
                  color: AppColors.ink4,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bone,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.line2),
              ),
              child: isEmpty
                  ? Text(
                      'No response given.',
                      style: AppTheme.body(
                          size: 13, color: AppColors.ink4),
                    )
                  : SelectableText(
                      widget.response.trim(),
                      style: AppTheme.body(
                        size: 13.5,
                        color: AppColors.ink2,
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Score ring ──────────────────────────────────────────────────────

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
      width: 96,
      height: 96,
      child: CustomPaint(
        painter: _RingPainter(fraction),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(centerTop,
                  style: AppTheme.mono(size: 24, color: AppColors.ink)),
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
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * fraction.clamp(0.0, 1.0),
      false,
      progress,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.fraction != fraction;
}

// ─── Stat tile ───────────────────────────────────────────────────────

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
              Text(value,
                  style: AppTheme.mono(size: 18, color: AppColors.ink)),
              Text(label,
                  style: AppTheme.body(size: 10.5, color: AppColors.ink4)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Detail row ──────────────────────────────────────────────────────

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
          Text(label,
              style: AppTheme.body(size: 12.5, color: AppColors.ink4)),
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
