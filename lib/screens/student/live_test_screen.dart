import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/niu_button.dart';

class LiveTestScreen extends StatefulWidget {
  const LiveTestScreen({super.key});

  @override
  State<LiveTestScreen> createState() => _LiveTestScreenState();
}

class _LiveTestScreenState extends State<LiveTestScreen> {
  int _currentQuestion = 13; // 0-indexed, showing Q14
  int _selectedOption = 1; // 0-indexed, option B selected by default
  int _timerSeconds = 46 * 60 + 23;
  Timer? _timer;

  // Track question states: 0=empty, 1=answered, 2=visited, 3=current
  final List<int> _questionStates = List.generate(60, (i) {
    if (i < 13 && i != 3 && i != 7 && i != 11) return 1; // answered
    if (i == 3 || i == 7 || i == 11) return 2; // visited
    if (i == 13) return 3; // current
    return 0; // empty
  });

  final String _questionText =
      'Which of the following is NOT a characteristic of a perfectly competitive market?';

  final List<String> _options = [
    'Large number of buyers and sellers',
    'Product differentiation',
    'Free entry and exit of firms',
    'Perfect information to all parties',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        setState(() => _timerSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final minutes = _timerSeconds ~/ 60;
    final seconds = _timerSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
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
                    'Q ${_currentQuestion + 1} / 60',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Text(
                    'MBA — NIU-SAT',
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formattedTime,
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
                children: List.generate(18, (i) {
                  final state = i < _questionStates.length
                      ? _questionStates[i]
                      : 0;
                  return _QuestionDot(number: i + 1, state: state);
                }),
              ),
            ),

            // Legend
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                children: [
                  _LegendItem(color: AppColors.green, label: 'Answered'),
                  const SizedBox(width: 12),
                  _LegendItem(
                    color: AppColors.bgGoldLight,
                    label: 'Visited',
                    borderColor: AppColors.borderGold,
                  ),
                  const SizedBox(width: 12),
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
                      _questionText,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Options
                    ...List.generate(_options.length, (i) {
                      final isSelected = i == _selectedOption;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedOption = i),
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
                                  _options[i],
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
                      onPressed: () {
                        if (_currentQuestion > 0) {
                          setState(() {
                            _questionStates[_currentQuestion] = 2;
                            _currentQuestion--;
                            _questionStates[_currentQuestion] = 3;
                          });
                        }
                      },
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
                      onPressed: () {
                        if (_currentQuestion < 59) {
                          setState(() {
                            _questionStates[_currentQuestion] = 1;
                            _currentQuestion++;
                            _questionStates[_currentQuestion] = 3;
                          });
                        }
                      },
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
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              child: NiuButton(
                label: 'Submit test',
                variant: NiuButtonVariant.gold,
                fontSize: 11,
                padding: const EdgeInsets.symmetric(vertical: 10),
                onTap: () =>
                    Navigator.pushReplacementNamed(context, AppRoutes.result),
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
  final int state; // 0=empty, 1=answered, 2=visited, 3=current

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
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: textColor),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final Color? borderColor;

  const _LegendItem({
    required this.color,
    required this.label,
    this.borderColor,
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
            border: borderColor != null ? Border.all(color: borderColor!) : null,
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
