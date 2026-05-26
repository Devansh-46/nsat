import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/eyebrow.dart';
import '../../widgets/note_box.dart';
import '../../services/test_management_service.dart';
import '../../models/test_model.dart';

/// Superadmin screen to manage per-test settings:
/// - Publish / unpublish test
/// - Enable / disable view results for students
/// - Enable / disable edit results for admins
class TestSettingsScreen extends StatefulWidget {
  const TestSettingsScreen({super.key});

  @override
  State<TestSettingsScreen> createState() => _TestSettingsScreenState();
}

class _TestSettingsScreenState extends State<TestSettingsScreen> {
  final TestManagementService _testMgmtService = TestManagementService();
  List<TestModel> _tests = [];
  bool _isLoading = true;
  String? _error;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _fetchTests();
  }

  Future<void> _fetchTests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final tests = await _testMgmtService.getAllTests();
      setState(() {
        _tests = tests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load tests';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleField(String testId, String field, bool currentValue) async {
    try {
      await _testMgmtService.updateTestFields(testId, {field: !currentValue});
      setState(() {
        _successMessage = 'Updated successfully';
      });
      await _fetchTests();
      _clearMessageAfterDelay();
    } catch (e) {
      setState(() {
        _error = 'Failed to update. Please try again.';
      });
      _clearMessageAfterDelay();
    }
  }

  void _clearMessageAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _successMessage = null;
          _error = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(22, topPad > 0 ? 12 : 24, 22, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  child: const Icon(Icons.arrow_back, size: 18, color: AppColors.ink3),
                ),
              ),
              const SizedBox(height: 16),
              const Eyebrow('test settings'),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  text: 'Manage ',
                  style: AppTheme.display(size: 26),
                  children: [AppTheme.italicSpan('tests.')],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Toggle publish status, view results, and edit results for each test.',
                style: AppTheme.body(size: 12.5, color: AppColors.ink4),
              ),
              const SizedBox(height: 24),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: NoteBox.clay(icon: Icons.error_outline, body: _error!),
                ),
              if (_successMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: NoteBox.green(icon: Icons.check_circle, body: _successMessage!),
                ),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
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
              else if (_tests.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'No tests found.',
                      style: AppTheme.body(color: AppColors.ink3),
                    ),
                  ),
                )
              else
                ..._tests.map((test) => _TestCard(
                      test: test,
                      onToggleField: _toggleField,
                    )),
            ],
          ),
        ),
      ),
    );
  }
}

class _TestCard extends StatelessWidget {
  final TestModel test;
  final Future<void> Function(String testId, String field, bool currentValue) onToggleField;

  const _TestCard({required this.test, required this.onToggleField});

  @override
  Widget build(BuildContext context) {
    final courseLabel = _courseDisplayLabels[test.course] ?? test.course;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        test.title,
                        style: AppTheme.body(
                          size: 14,
                          color: AppColors.ink,
                          weight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$courseLabel  ·  ${test.questionCount} questions  ·  ${test.durationMinutes} min',
                        style: AppTheme.body(size: 11, color: AppColors.ink4),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: test.isPublished
                        ? AppColors.forestTint
                        : AppColors.bone,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    test.isPublished ? 'Published' : 'Draft',
                    style: AppTheme.body(
                      size: 10,
                      color: test.isPublished ? AppColors.forest : AppColors.ink3,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.line2),
            const SizedBox(height: 8),

            // Toggle: Publish
            _ToggleRow(
              label: 'Publish test',
              description: 'Students can take this test',
              value: test.isPublished,
              onToggle: () => onToggleField(test.id, 'isPublished', test.isPublished),
            ),

            const Divider(height: 1, color: AppColors.line2),

            // Toggle: View Results (student-facing)
            _ToggleRow(
              label: 'View results',
              description: 'Students see their score after submission',
              value: test.showResults,
              onToggle: () => onToggleField(test.id, 'showResults', test.showResults),
            ),

            const Divider(height: 1, color: AppColors.line2),

            // Toggle: Edit Results (admin-facing)
            _ToggleRow(
              label: 'Edit results',
              description: 'Admins can edit results for this test',
              value: test.allowEditResults,
              onToggle: () => onToggleField(test.id, 'allowEditResults', test.allowEditResults),
            ),

            const Divider(height: 1, color: AppColors.line2),

            // Toggle: Allow View Results for admins
            _ToggleRow(
              label: 'Admin view results',
              description: 'Admins can view results for this test',
              value: test.allowViewResults,
              onToggle: () => onToggleField(test.id, 'allowViewResults', test.allowViewResults),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final String description;
  final bool value;
  final VoidCallback onToggle;

  const _ToggleRow({
    required this.label,
    required this.description,
    required this.value,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.body(
                    size: 12.5,
                    color: AppColors.ink,
                    weight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  description,
                  style: AppTheme.body(size: 10.5, color: AppColors.ink4),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 24,
              decoration: BoxDecoration(
                color: value ? AppColors.forest : AppColors.line,
                borderRadius: BorderRadius.circular(12),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _courseDisplayLabels = {
  'soahs_ug': 'SOAHS UG',
  'soahs_pg': 'SOAHS PG',
  'son': 'Nursing',
  'set_ug': 'Engineering UG',
  'set_pg': 'Engineering PG',
  'sbm_ug': 'Business UG',
  'sbm_pg': 'Business PG',
  'solla_ug': 'Law UG',
  'solla_pg': 'Law PG',
  'sjmc': 'Journalism',
  'sos_ug': 'Science UG',
  'sos_pg': 'Science PG',
  'sola': 'Liberal Arts',
  'soe': 'Education',
  'sop': 'Pharmacy',
};
