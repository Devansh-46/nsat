import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/niu_app_bar.dart';
import '../../widgets/niu_button.dart';
import '../../providers/auth_provider.dart';
import '../../providers/test_provider.dart';

/// Shows the published test for the verified student's course and lets
/// them start it.
///
/// Identity comes from AuthProvider.verifiedStudent (set by the fee
/// gate) — a StudentModel carrying applicationNo, name and course.
/// No UserModel, no ACCSOFT.
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

    // Not started — show why.
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
      backgroundColor: Colors.white,
      body: Column(
        children: [
          NiuAppBar(
            title: 'Your test',
            subtitle: 'Hello, ${lead?.name ?? ''}',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (testProvider.isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (test != null) ...[
                    Text(
                      test.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2.2,
                      children: [
                        _DetailCard(
                          value: test.questionCount.toString(),
                          label: 'Questions',
                        ),
                        _DetailCard(
                          value: test.durationMinutes.toString(),
                          label: 'Minutes',
                        ),
                        _DetailCard(
                          value: test.marksPerQuestion.toStringAsFixed(1),
                          label: 'Mark per Q',
                        ),
                        _DetailCard(
                          value: test.negativeMarking
                              ? '-${test.negativeMarksPerWrong}'
                              : '0',
                          label: 'Wrong ans.',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.bgGoldLight,
                        border: Border.all(color: AppColors.borderGold),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'One attempt only. The test cannot be retaken '
                        'once started.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textGold,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    NiuButton(label: 'Start test', onTap: _startTest),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        border: Border.all(color: AppColors.borderLight),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.info_outline,
                              color: AppColors.textMuted, size: 40),
                          const SizedBox(height: 12),
                          const Text(
                            'No test available',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
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
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String value;
  final String label;

  const _DetailCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: Border.all(color: AppColors.borderLight, width: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}