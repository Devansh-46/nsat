import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/niu_button.dart';
import '../../providers/auth_provider.dart';
import '../../providers/test_provider.dart';

/// Shows the published test for the verified student's course and lets
/// them start it. Identity comes from AuthProvider (verifiedStudent +
/// leadDetails). Visual design is consistent with the approved screens.
class TestCategoryScreen extends StatefulWidget {
  const TestCategoryScreen({super.key});

  @override
  State<TestCategoryScreen> createState() => _TestCategoryScreenState();
}

class _TestCategoryScreenState extends State<TestCategoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lead = context.read<AuthProvider>().leadDetails;
      if (lead != null) {
        // lead.courseKey is the canonical key (e.g. "btech").
        context.read<TestProvider>().fetchAvailableTest(lead.courseKey);
      }
    });
  }

  void _startTest() async {
    final auth = context.read<AuthProvider>();
    final testProvider = context.read<TestProvider>();

    final student = auth.verifiedStudent;
    final lead = auth.leadDetails;
    if (student == null || lead == null) return;

    final started = await testProvider.startTest(
      applicationNo: student.applicationNo,
      studentName: lead.name,
      course: lead.courseKey,
    );

    if (!mounted) return;

    if (started) {
      Navigator.pushReplacementNamed(context, AppRoutes.liveTest);
      return;
    }

    if (testProvider.alreadyCompleted) {
      _showBlocked(
        'Test already completed',
        'Our records show this NIU ID has already taken the test. '
            'It can only be attempted once.',
      );
    } else if (testProvider.hasResumableAttempt) {
      _showBlocked(
        'Unfinished attempt found',
        'An earlier attempt for this NIU ID was started but not '
            'finished. Please contact an invigilator.',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(testProvider.error ?? 'Could not start the test.'),
        ),
      );
    }
  }

  void _showBlocked(String title, String body) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lead = context.watch<AuthProvider>().leadDetails;
    final testProvider = context.watch<TestProvider>();
    final test = testProvider.availableTest;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Greeting ---
              const Text(
                'Your test',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Hello, ${lead?.name ?? 'Student'}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              if (testProvider.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (test != null) ...[
                // --- Test card ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.bgGreenLight,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(Icons.assignment_outlined,
                                size: 20, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              test.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Detail tiles — 2x2.
                      Row(
                        children: [
                          Expanded(
                            child: _DetailTile(
                              value: '${test.questionCount}',
                              label: 'Questions',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _DetailTile(
                              value: '${test.durationMinutes}',
                              label: 'Minutes',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _DetailTile(
                              value: test.marksPerQuestion
                                  .toStringAsFixed(0),
                              label: 'Mark / question',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _DetailTile(
                              value: test.negativeMarking
                                  ? '-${test.negativeMarksPerWrong}'
                                  : '0',
                              label: 'Wrong answer',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // --- One-attempt warning ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: AppColors.bgGoldLight,
                    border: Border.all(
                        color: AppColors.borderGold
                            .withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.warning_amber_rounded,
                          size: 16, color: AppColors.textGold),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'One attempt only. Once you start, the test '
                          'cannot be retaken — make sure you are ready.',
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
                const SizedBox(height: 18),

                NiuButton(label: 'Start test', onTap: _startTest),
              ] else ...[
                // --- No test available ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 38, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      const Text(
                        'No test available',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        testProvider.error ??
                            'There is no published test for your '
                                'course yet.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One detail tile in the test card.
class _DetailTile extends StatelessWidget {
  final String value;
  final String label;

  const _DetailTile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}