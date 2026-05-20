import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../widgets/niu_button.dart';
import '../../providers/test_provider.dart';

/// Live test — one question per screen, progress bar, timer, palette.
/// Verdant Daylight reskin. All logic identical to the previous build.
class LiveTestScreen extends StatefulWidget {
  const LiveTestScreen({super.key});

  @override
  State<LiveTestScreen> createState() => _LiveTestScreenState();
}

class _LiveTestScreenState extends State<LiveTestScreen> {
  int _currentIndex = 0;

  String _formatTime(int seconds) {
    if (seconds < 0) seconds = 0;
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _submitTest() async {
    final provider = context.read<TestProvider>();
    await provider.submitTest();
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.result);
    }
  }

  void _openPalette(TestProvider provider) {
    final session = provider.currentSession!;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.ivory,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Questions', style: AppTheme.displaySm(size: 16)),
            const SizedBox(height: 4),
            Text(
              '${session.answeredCount} of ${session.totalQuestions} answered',
              style: AppTheme.body(size: 12, color: AppColors.ink4),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(session.totalQuestions, (i) {
                final answered = session.answers.containsKey(i);
                final current = i == _currentIndex;
                return GestureDetector(
                  onTap: () {
                    setState(() => _currentIndex = i);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: current
                          ? AppColors.forest
                          : answered
                              ? AppColors.forestTint
                              : AppColors.bone,
                      border: Border.all(
                        color: current
                            ? AppColors.forest
                            : answered
                                ? AppColors.forest.withValues(alpha: 0.3)
                                : AppColors.line,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: AppTheme.mono(
                        size: 12,
                        color: current
                            ? Colors.white
                            : answered
                                ? AppColors.forest
                                : AppColors.ink4,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _confirmSubmit(TestProvider provider) {
    final session = provider.currentSession!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.ivory,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text('Submit test?', style: AppTheme.displaySm(size: 18)),
        content: Text(
          'You have answered ${session.answeredCount} of '
          '${session.totalQuestions} questions.\n\n'
          'Once submitted, the test cannot be changed.',
          style: AppTheme.body(size: 13.5, color: AppColors.ink3),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: AppTheme.body(
                    size: 14, color: AppColors.ink4, weight: FontWeight.w500)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _submitTest();
            },
            child: Text('Submit',
                style: AppTheme.body(
                    size: 14,
                    color: AppColors.forest,
                    weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TestProvider>();
    final session = provider.currentSession;

    if (session == null) {
      return Scaffold(
        backgroundColor: AppColors.bgBase,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('No active test session found.',
                  style: AppTheme.body(color: AppColors.ink3)),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: NiuButton(
                  label: 'Go back',
                  variant: NiuButtonVariant.outline,
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (session.isSubmitted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, AppRoutes.result);
      });
    }

    final question = session.questions[_currentIndex];
    final selected = session.answers[_currentIndex];
    final progress = (_currentIndex + 1) / session.totalQuestions;
    final timeLow = session.timeRemainingSeconds <= 300;

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
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
                        Text(
                          session.categoryName,
                          style: AppTheme.eyebrow(color: AppColors.ink4),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Question ${_currentIndex + 1} '
                          'of ${session.totalQuestions}',
                          style: AppTheme.displaySm(size: 15),
                        ),
                      ],
                    ),
                  ),
                  // Timer
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: timeLow ? AppColors.goldTint : AppColors.forestTint,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: timeLow
                            ? AppColors.gold.withValues(alpha: 0.3)
                            : AppColors.forest.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: timeLow
                              ? const Color(0xFF8A6516)
                              : AppColors.forest,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _formatTime(session.timeRemainingSeconds),
                          style: AppTheme.mono(
                            size: 13,
                            color: timeLow
                                ? const Color(0xFF8A6516)
                                : AppColors.forest,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Progress bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: AppColors.bone,
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.forest),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── Answered + Review ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${session.answeredCount} answered',
                    style: AppTheme.body(size: 11.5, color: AppColors.ink4),
                  ),
                  GestureDetector(
                    onTap: () => _openPalette(provider),
                    child: Row(
                      children: [
                        const Icon(Icons.grid_view_rounded,
                            size: 13, color: AppColors.forest),
                        const SizedBox(width: 4),
                        Text(
                          'Review',
                          style: AppTheme.body(
                            size: 11.5,
                            color: AppColors.forest,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Question + options ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.text,
                      style: AppTheme.body(
                        size: 15,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ...List.generate(question.options.length, (i) {
                      final isSelected = i == selected;
                      final letter = String.fromCharCode(65 + i);
                      return GestureDetector(
                        onTap: () =>
                            provider.selectAnswer(_currentIndex, i),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 13),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? AppColors.glassBgStrong
                                : AppColors.glassBg,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.forest
                                  : AppColors.glassBorder,
                              width: isSelected ? 1.5 : 1,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: isSelected
                                ? const [
                                    BoxShadow(
                                      color: Color(0x1A2C6B42),
                                      offset: Offset(0, 0),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.forest
                                      : AppColors.bone,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  letter,
                                  style: AppTheme.mono(
                                    size: 12,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.ink4,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  question.options[i],
                                  style: AppTheme.body(
                                    size: 13.5,
                                    color: AppColors.ink,
                                    weight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                              // Radio dot
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? AppColors.forest
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.forest
                                        : AppColors.ink5,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Center(
                                        child: Icon(Icons.circle,
                                            size: 7,
                                            color: Colors.white),
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    if (selected != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () =>
                              provider.clearAnswer(_currentIndex),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 32),
                          ),
                          child: Text(
                            'Clear selection',
                            style: AppTheme.body(
                              size: 11.5,
                              color: AppColors.ink4,
                            ).copyWith(
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Bottom nav ──
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: BoxDecoration(
                color: AppColors.ivory,
                border: Border(
                  top: BorderSide(color: AppColors.line2),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: NiuButton(
                          label: 'Previous',
                          variant: NiuButtonVariant.outline,
                          onTap: _currentIndex > 0
                              ? () => setState(() => _currentIndex--)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _currentIndex < session.totalQuestions - 1
                            ? NiuButton(
                                label: 'Next',
                                onTap: () =>
                                    setState(() => _currentIndex++),
                              )
                            : NiuButton(
                                label: 'Submit test',
                                variant: NiuButtonVariant.gold,
                                onTap: () => _confirmSubmit(provider),
                              ),
                      ),
                    ],
                  ),
                  if (provider.isLoading) ...[
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      minHeight: 2,
                      backgroundColor: AppColors.bone,
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.forest),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}