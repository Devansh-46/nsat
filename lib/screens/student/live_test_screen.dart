import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../widgets/niu_button.dart';
import '../../providers/test_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/analytics_service.dart';
import '../../widgets/web_split_layout.dart';

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
    final auth = context.read<AuthProvider>();
    await provider.submitTest();
    if (mounted) {
      final session = provider.currentSession;
      final student = auth.verifiedStudent;
      if (session != null && student != null) {
        AnalyticsService.instance.logTestSubmitted(
          applicationNo: student.applicationNo,
          course: session.categoryName,
          answeredCount: session.answeredCount,
          totalQuestions: session.totalQuestions,
        );
      }
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

    final mobileView = Scaffold(
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

            // ── Question + options / short answer ──
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
                    if (question.isShortAnswer)
                      _ShortAnswerField(
                        currentAnswer: selected is String ? selected : '',
                        minWords: question.minWords > 0 ? question.minWords : 100,
                        maxWords: question.maxWords > 0 ? question.maxWords : 150,
                        onChanged: (value) =>
                            provider.selectAnswer(_currentIndex, value),
                        onClear: () => provider.clearAnswer(_currentIndex),
                      )
                    else ...[
                      ...List.generate(question.options.length, (i) {
                        final isSelected = selected is int && i == selected;
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
                      if (selected != null && selected is int)
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

    final leftPanel = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('NSAT', style: AppTheme.mono(color: AppColors.ivory.withValues(alpha: 0.5))),
            const SizedBox(width: 8),
            Text('/', style: AppTheme.mono(color: AppColors.ivory.withValues(alpha: 0.2))),
            const SizedBox(width: 8),
            Text('NOIDA INTERNATIONAL UNIVERSITY', style: AppTheme.eyebrow(color: AppColors.ivory.withValues(alpha: 0.5))),
          ],
        ),
        const SizedBox(height: 16),
        Text('Student / Live test', style: AppTheme.body(size: 14, color: AppColors.ivory)),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text('STEP 04 OF 04 — EXAM IN PROGRESS', style: AppTheme.eyebrow(color: AppColors.ivory)),
        ),
        const SizedBox(height: 32),
        
        // Timer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: timeLow ? AppColors.goldTint : AppColors.forestTint,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: timeLow ? AppColors.gold.withValues(alpha: 0.3) : AppColors.forest.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer_outlined, size: 20, color: timeLow ? const Color(0xFF8A6516) : AppColors.forest),
              const SizedBox(width: 8),
              Text(
                _formatTime(session.timeRemainingSeconds),
                style: AppTheme.mono(size: 24, color: timeLow ? const Color(0xFF8A6516) : AppColors.forest),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        
        // Progress text
        Text(
          '${session.answeredCount} of ${session.totalQuestions} answered',
          style: AppTheme.body(size: 14, color: AppColors.ivory.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 16),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: AppColors.ivory.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation(AppColors.ivory),
          ),
        ),
        const SizedBox(height: 32),

        // Palette
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(session.totalQuestions, (i) {
                final answered = session.answers.containsKey(i);
                final current = i == _currentIndex;
                return GestureDetector(
                  onTap: () => setState(() => _currentIndex = i),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: current
                          ? AppColors.ivory
                          : answered
                              ? AppColors.ivory.withValues(alpha: 0.2)
                              : Colors.transparent,
                      border: Border.all(
                        color: current
                            ? AppColors.ivory
                            : answered
                                ? AppColors.ivory.withValues(alpha: 0.5)
                                : AppColors.ivory.withValues(alpha: 0.2),
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: AppTheme.mono(
                        size: 12,
                        color: current ? AppColors.bgBase : AppColors.ivory,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );

    final rightPanel = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          session.categoryName,
          style: AppTheme.eyebrow(color: AppColors.ink4),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          'Question ${_currentIndex + 1} of ${session.totalQuestions}',
          style: AppTheme.display(size: 28),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.text,
                  style: AppTheme.body(
                    size: 16,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 24),
                if (question.isShortAnswer)
                  _ShortAnswerField(
                    currentAnswer: selected is String ? selected : '',
                    minWords: question.minWords > 0 ? question.minWords : 100,
                    maxWords: question.maxWords > 0 ? question.maxWords : 150,
                    onChanged: (value) => provider.selectAnswer(_currentIndex, value),
                    onClear: () => provider.clearAnswer(_currentIndex),
                  )
                else ...[
                  ...List.generate(question.options.length, (i) {
                    final isSelected = selected is int && i == selected;
                    final letter = String.fromCharCode(65 + i);
                    return GestureDetector(
                      onTap: () => provider.selectAnswer(_currentIndex, i),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          gradient: isSelected ? AppColors.glassBgStrong : AppColors.glassBg,
                          border: Border.all(
                            color: isSelected ? AppColors.forest : AppColors.glassBorder,
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
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.forest : AppColors.bone,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                letter,
                                style: AppTheme.mono(
                                  size: 14,
                                  color: isSelected ? Colors.white : AppColors.ink4,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                question.options[i],
                                style: AppTheme.body(
                                  size: 15,
                                  color: AppColors.ink,
                                  weight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ),
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? AppColors.forest : Colors.transparent,
                                border: Border.all(
                                  color: isSelected ? AppColors.forest : AppColors.ink5,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? const Center(
                                      child: Icon(Icons.circle, size: 8, color: Colors.white),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  if (selected != null && selected is int)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => provider.clearAnswer(_currentIndex),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                        ),
                        child: Text(
                          'Clear selection',
                          style: AppTheme.body(
                            size: 13,
                            color: AppColors.ink4,
                          ).copyWith(decoration: TextDecoration.underline),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
        
        // Bottom nav
        Container(
          padding: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.line2)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: NiuButton(
                      label: 'Previous',
                      variant: NiuButtonVariant.outline,
                      onTap: _currentIndex > 0 ? () => setState(() => _currentIndex--) : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _currentIndex < session.totalQuestions - 1
                        ? NiuButton(
                            label: 'Next',
                            onTap: () => setState(() => _currentIndex++),
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
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: AppColors.bone,
                  valueColor: const AlwaysStoppedAnimation(AppColors.forest),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    return WebSplitLayout(
      leftChild: leftPanel,
      rightChild: rightPanel,
      mobileChild: mobileView,
    );
  }
}

// ─── Short answer text field ────────────────────────────────────────

class _ShortAnswerField extends StatefulWidget {
  final String currentAnswer;
  final int minWords;
  final int maxWords;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _ShortAnswerField({
    required this.currentAnswer,
    required this.onChanged,
    required this.onClear,
    this.minWords = 100,
    this.maxWords = 150,
  });

  @override
  State<_ShortAnswerField> createState() => _ShortAnswerFieldState();
}

class _ShortAnswerFieldState extends State<_ShortAnswerField> {
  late final TextEditingController _controller;
  int _wordCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentAnswer);
    _wordCount = _countWords(widget.currentAnswer);
  }

  @override
  void didUpdateWidget(_ShortAnswerField old) {
    super.didUpdateWidget(old);
    if (old.currentAnswer != widget.currentAnswer) {
      _controller.text = widget.currentAnswer;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
      setState(() => _wordCount = _countWords(widget.currentAnswer));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _countWords(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).length;
  }

  Color get _wordCountColor {
    if (_wordCount == 0) return AppColors.ink4;
    if (_wordCount < widget.minWords) return const Color(0xFF8A6516); // gold
    if (_wordCount > widget.maxWords) return AppColors.clay;
    return AppColors.forest; // in range
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hint label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.forestTint,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.edit_note, size: 16, color: AppColors.forest),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Write your answer in ${widget.minWords}–${widget.maxWords} words',
                  style: AppTheme.body(
                    size: 12,
                    color: AppColors.forest,
                    weight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Text field
        Container(
          decoration: BoxDecoration(
            gradient: AppColors.glassBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: TextField(
            controller: _controller,
            onChanged: (value) {
              setState(() => _wordCount = _countWords(value));
              widget.onChanged(value);
            },
            maxLines: 8,
            minLines: 5,
            style: AppTheme.body(size: 14.5, color: AppColors.ink),
            cursorColor: AppColors.forest,
            decoration: InputDecoration(
              hintText: 'Type your answer here…',
              hintStyle: AppTheme.body(size: 14.5, color: AppColors.ink4),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Word count + clear row
        Row(
          children: [
            Text(
              '$_wordCount word${_wordCount == 1 ? '' : 's'}',
              style: AppTheme.mono(size: 12, color: _wordCountColor),
            ),
            const SizedBox(width: 6),
            if (_wordCount > 0 && _wordCount < widget.minWords)
              Text(
                '(${widget.minWords - _wordCount} more needed)',
                style: AppTheme.body(size: 11, color: _wordCountColor),
              )
            else if (_wordCount > widget.maxWords)
              Text(
                '(${_wordCount - widget.maxWords} over limit)',
                style: AppTheme.body(size: 11, color: AppColors.clay),
              ),
            const Spacer(),
            if (_controller.text.trim().isNotEmpty)
              GestureDetector(
                onTap: () {
                  _controller.clear();
                  setState(() => _wordCount = 0);
                  widget.onClear();
                },
                child: Text(
                  'Clear',
                  style: AppTheme.body(
                    size: 11.5,
                    color: AppColors.ink4,
                  ).copyWith(decoration: TextDecoration.underline),
                ),
              ),
          ],
        ),

        // Note about this question being ungraded
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.bone,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 13, color: AppColors.ink4),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'This question is not scored. Your response will be reviewed by the admissions team.',
                  style: AppTheme.body(size: 11, color: AppColors.ink4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}