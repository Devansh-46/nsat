import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/niu_button.dart';
import '../../providers/test_provider.dart';

/// Live test screen — one question per screen, calm progress bar and
/// timer. Follows the approved live-test mockup (deep forest theme).
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

  /// Opens the question palette as a bottom sheet (the "Review" action).
  void _openPalette(TestProvider provider) {
    final session = provider.currentSession!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Questions',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${session.answeredCount} of ${session.totalQuestions} answered',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
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
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: current
                          ? AppColors.primary
                          : answered
                              ? AppColors.bgGreenLight
                              : AppColors.bgCard,
                      border: Border.all(
                        color: current
                            ? AppColors.primary
                            : answered
                                ? AppColors.green
                                : AppColors.border,
                      ),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: current
                            ? Colors.white
                            : answered
                                ? AppColors.textGreen
                                : AppColors.textMuted,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
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
        title: const Text('Submit test?'),
        content: Text(
          'You have answered ${session.answeredCount} of '
          '${session.totalQuestions} questions.\n\n'
          'Once submitted, the test cannot be changed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _submitTest();
            },
            child: const Text('Submit'),
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
        backgroundColor: AppColors.bgLight,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No active test session found.'),
              const SizedBox(height: 16),
              NiuButton(
                label: 'Go back',
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
    }

    // Auto-submitted by the timer — move to results.
    if (session.isSubmitted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, AppRoutes.result);
      });
    }

    final question = session.questions[_currentIndex];
    final selected = session.answers[_currentIndex];
    final progress =
        (_currentIndex + 1) / session.totalQuestions;
    final timeLow = session.timeRemainingSeconds <= 300; // last 5 min

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // --- Header: back, title, timer ---
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(Icons.chevron_left,
                          size: 20, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.categoryName,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Question ${_currentIndex + 1} '
                          'of ${session.totalQuestions}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Timer chip.
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: timeLow
                          ? AppColors.bgWarning
                          : AppColors.bgGreenLight,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: timeLow
                              ? AppColors.textOrange
                              : AppColors.textGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(session.timeRemainingSeconds),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: timeLow
                                ? AppColors.textOrange
                                : AppColors.textGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // --- Progress bar ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation(
                      AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // --- Answered count + Review ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${session.answeredCount} answered',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _openPalette(provider),
                    child: Row(
                      children: const [
                        Icon(Icons.grid_view_rounded,
                            size: 13, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text(
                          'Review',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --- Question + options ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.text,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(question.options.length, (i) {
                      final isSelected = i == selected;
                      final letter = String.fromCharCode(65 + i); // A..D
                      return GestureDetector(
                        onTap: () =>
                            provider.selectAnswer(_currentIndex, i),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.bgGreenLight
                                : Colors.white,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: isSelected ? 1.5 : 1,
                            ),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.bgCard,
                                  borderRadius:
                                      BorderRadius.circular(7),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  letter,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textMuted,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  question.options[i],
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: isSelected
                                        ? AppColors.textPrimary
                                        : AppColors.textPrimary,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              // Radio dot.
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.border,
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
                          child: const Text(
                            'Clear selection',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // --- Bottom nav: Previous / Next / Submit ---
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                      color: AppColors.borderLight, width: 0.5),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _currentIndex > 0
                              ? () =>
                                  setState(() => _currentIndex--)
                              : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(
                                color: AppColors.border),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 13),
                          ),
                          child: const Text('Previous',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child:
                            _currentIndex < session.totalQuestions - 1
                                ? ElevatedButton(
                                    onPressed: () => setState(
                                        () => _currentIndex++),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          AppColors.primary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(
                                                  10)),
                                      padding:
                                          const EdgeInsets.symmetric(
                                              vertical: 13),
                                    ),
                                    child: const Text('Next',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight:
                                                FontWeight.w700)),
                                  )
                                : ElevatedButton(
                                    onPressed: () =>
                                        _confirmSubmit(provider),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          AppColors.gold,
                                      foregroundColor:
                                          AppColors.primary,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(
                                                  10)),
                                      padding:
                                          const EdgeInsets.symmetric(
                                              vertical: 13),
                                    ),
                                    child: const Text('Submit test',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight:
                                                FontWeight.w700)),
                                  ),
                      ),
                    ],
                  ),
                  if (provider.isLoading) ...[
                    const SizedBox(height: 10),
                    const LinearProgressIndicator(minHeight: 2),
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