import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/test_provider.dart';
import '../../services/fcm_service.dart';
import '../../widgets/mesh_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/eyebrow.dart';
import '../../widgets/niu_button.dart';
import '../../widgets/note_box.dart';
import '../../services/remote_config_service.dart';
import '../../services/analytics_service.dart';
/// Step 3 — Shows the student's published test and lets them start it.
/// Identity from AuthProvider (verifiedStudent + leadDetails).
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
        context.read<TestProvider>().fetchAvailableTest(lead.courseKey);
        // Subscribe to FCM topics for this student's school
        FcmService().initializeForStudent(lead.courseKey);
      }
    });
  }

  void _startTest() async {
    // Check if exam window is open
    await RemoteConfigService.instance.refresh();
    final rc = RemoteConfigService.instance;

    if (!mounted) return;

    if (rc.isMaintenanceMode) {
      AnalyticsService.instance.logMaintenanceBlocked();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(rc.maintenanceMessage)),
      );
      return;
    }

    if (!rc.isExamWindowOpen) {
      final auth = context.read<AuthProvider>();
      final student = auth.verifiedStudent;
      if (student != null) {
        AnalyticsService.instance.logExamWindowBlocked(applicationNo: student.applicationNo);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The exam window is currently closed. '
              'Please wait for the scheduled time.'),
        ),
      );
      return;
    }

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
      AnalyticsService.instance.logTestStarted(
        applicationNo: student.applicationNo,
        course: lead.courseKey,
        testId: testProvider.availableTest?.id ?? '',
      );
      Navigator.pushReplacementNamed(context, AppRoutes.liveTest);
      return;
    }

    if (testProvider.alreadyCompleted) {
      AnalyticsService.instance.logAlreadyCompleted(applicationNo: student.applicationNo);
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
        backgroundColor: AppColors.ivory,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text(title, style: AppTheme.displaySm(size: 18)),
        content: Text(body, style: AppTheme.body(size: 13.5, color: AppColors.ink3)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'OK',
              style: AppTheme.body(
                size: 14,
                color: AppColors.forest,
                weight: FontWeight.w600,
              ),
            ),
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
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: MeshBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(22, topPad > 0 ? 12 : 28, 22, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Greeting ──
                const Eyebrow('your test'),
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    text: 'Hello, ',
                    style: AppTheme.display(size: 28),
                    children: [
                      AppTheme.italicSpan(
                        '${lead?.name ?? "Student"}.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                if (testProvider.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.forest,
                        ),
                      ),
                    ),
                  )
                else if (test != null) ...[
                  // ── Test card ──
                  GlassCard(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.forestTint,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.assignment_outlined,
                                  size: 20, color: AppColors.forest),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                test.title,
                                style: AppTheme.displaySm(size: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 2×2 stat grid
                        Row(
                          children: [
                            Expanded(
                              child: _StatTile(
                                value: '${test.questionCount}',
                                label: 'Questions',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatTile(
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
                              child: _StatTile(
                                value: test.marksPerQuestion
                                    .toStringAsFixed(0),
                                label: 'Mark / question',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatTile(
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
                  const SizedBox(height: 16),

                  // One-attempt warning
                  const NoteBox.gold(
                    icon: Icons.warning_amber_rounded,
                    title: 'One attempt only',
                    body: 'Once you start, the test cannot be retaken '
                        '— make sure you are ready.',
                  ),
                  const SizedBox(height: 20),

                  NiuButton(
                    label: 'Start test',
                    variant: NiuButtonVariant.forest,
                    showArrow: true,
                    onTap: _startTest,
                  ),
                ] else ...[
                  // ── Empty state ──
                  GlassCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 36),
                    child: Column(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 36, color: AppColors.ink4),
                        const SizedBox(height: 14),
                        Text(
                          'No test available',
                          style: AppTheme.displaySm(size: 17),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          testProvider.error ??
                              'There is no published test for your '
                                  'course yet.',
                          textAlign: TextAlign.center,
                          style: AppTheme.body(
                            size: 13,
                            color: AppColors.ink3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 28),
                const _StepIndicator(current: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Stat tile ──────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  const _StatTile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.bone,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line2),
      ),
      child: Column(
        children: [
          Text(value, style: AppTheme.mono(size: 22, color: AppColors.forest)),
          const SizedBox(height: 3),
          Text(
            label.toUpperCase(),
            style: AppTheme.eyebrow(color: AppColors.ink4),
          ),
        ],
      ),
    );
  }
}

// ─── Step indicator (step 3) ────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int current;
  const _StepIndicator({this.current = 0});

  static const _labels = ['ID', 'Email', 'Verify', 'Test'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final active = i == current;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 22 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: active ? AppColors.forest : AppColors.bone,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        Text.rich(
          TextSpan(
            style: AppTheme.body(size: 11.5, color: AppColors.ink4),
            children: [
              TextSpan(
                text: 'Step ${current + 1} of 4',
                style: AppTheme.body(
                  size: 11.5,
                  color: AppColors.ink3,
                  weight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: '  ·  '),
              for (int i = 0; i < _labels.length; i++) ...[
                if (i > 0) const TextSpan(text: '  ›  '),
                TextSpan(
                  text: _labels[i],
                  style: AppTheme.body(
                    size: 11.5,
                    color: i == current ? AppColors.forest : AppColors.ink4,
                    weight: i == current ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}