import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/niu_button.dart';
import '../../providers/test_provider.dart';

class LiveTestScreen extends StatefulWidget {
  const LiveTestScreen({super.key});

  @override
  State<LiveTestScreen> createState() => _LiveTestScreenState();
}

class _LiveTestScreenState extends State<LiveTestScreen> {
  int _currentIndex = 0;

  String _formatTime(int seconds) {
    if (seconds < 0) return '00:00';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _submitTest() async {
    final provider = context.read<TestProvider>();
    await provider.submitTest();
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TestProvider>();
    final session = provider.currentSession;

    // Safety fallback if accessed without session
    if (session == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No active test session found.'),
              const SizedBox(height: 16),
              NiuButton(
                label: 'Go Back',
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
    }

    final currentQuestion = session.questions[_currentIndex];
    final selectedOption = session.answers[_currentIndex];

    // Check if auto-submitted
    if (session.isSubmitted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, AppRoutes.result);
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Question header
            Container(
              color: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Q ${_currentIndex + 1} / ${session.totalQuestions}',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    session.categoryName,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatTime(session.timeRemainingSeconds),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Question palette
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: AppColors.bgCard,
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: List.generate(session.totalQuestions, (i) {
                  final state = session.getQuestionState(i, _currentIndex);
                  return GestureDetector(
                    onTap: () => setState(() => _currentIndex = i),
                    child: _QuestionDot(number: i + 1, state: state),
                  );
                }),
              ),
            ),

            // Legend
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: const Row(
                children: [
                  _LegendItem(color: AppColors.green, label: 'Answered'),
                  SizedBox(width: 12),
                  _LegendItem(
                    color: Color(0xFFF0F0F0),
                    label: 'Unanswered',
                  ),
                  SizedBox(width: 12),
                  _LegendItem(color: AppColors.primary, label: 'Current'),
                ],
              ),
            ),

            // Question body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentQuestion.text,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Clear selection btn
                    if (selectedOption != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => provider.clearAnswer(_currentIndex),
                          child: const Text('Clear Selection',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.red)),
                        ),
                      ),

                    // Options
                    ...List.generate(currentQuestion.options.length, (i) {
                      final isSelected = i == selectedOption;
                      return GestureDetector(
                        onTap: () => provider.selectAnswer(_currentIndex, i),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 7),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 9),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                            color: isSelected ? AppColors.bgInfo : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
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
                                        : const Color(0xFFCCCCCC),
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? Center(
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  currentQuestion.options[i],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                    fontWeight: isSelected
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _currentIndex > 0
                          ? () => setState(() => _currentIndex--)
                          : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('Prev',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _currentIndex < session.totalQuestions - 1
                          ? () => setState(() => _currentIndex++)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 0,
                      ),
                      child: const Text('Next',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500)),
                    ),
                  ),
                ],
              ),
            ),

            // Submit button
            if (provider.isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                child: NiuButton(
                  label: 'Submit test',
                  variant: NiuButtonVariant.gold,
                  fontSize: 11,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Submit Test?'),
                        content: Text(
                            'You have answered ${session.answeredCount} out of ${session.totalQuestions} questions.\n\nAre you sure you want to submit?'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel')),
                          ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _submitTest();
                              },
                              child: const Text('Submit')),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuestionDot extends StatelessWidget {
  final int number;
  final int state; // 0=unanswered, 1=answered, 2=visited, 3=current

  const _QuestionDot({required this.number, required this.state});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color textColor;
    Border? border;

    switch (state) {
      case 1:
        bg = AppColors.green;
        textColor = Colors.white;
        break;
      case 2:
        bg = AppColors.bgGoldLight;
        textColor = AppColors.textGold;
        border = Border.all(color: AppColors.borderGold, width: 1);
        break;
      case 3:
        bg = AppColors.primary;
        textColor = Colors.white;
        break;
      default:
        bg = const Color(0xFFF0F0F0);
        textColor = AppColors.textMuted;
    }

    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
        border: border,
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: TextStyle(
            fontSize: 9, fontWeight: FontWeight.w500, color: textColor),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
