import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/eyebrow.dart';
import '../../widgets/note_box.dart';

/// Course access management — super admin assigns which courses each admin can see.
class CourseAccessScreen extends StatefulWidget {
  const CourseAccessScreen({super.key});

  @override
  State<CourseAccessScreen> createState() => _CourseAccessScreenState();
}

class _CourseAccessScreenState extends State<CourseAccessScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchAdmins();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
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
              const Eyebrow('access control'),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  text: 'Course ',
                  style: AppTheme.display(size: 26),
                  children: [AppTheme.italicSpan('access.')],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Assign which course results each admin can view. Changes apply on next login.',
                style: AppTheme.body(size: 12.5, color: AppColors.ink4),
              ),
              const SizedBox(height: 24),

              if (admin.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: NoteBox.clay(icon: Icons.error_outline, body: admin.error!),
                ),
              if (admin.successMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: NoteBox.green(icon: Icons.check_circle, body: admin.successMessage!),
                ),

              // Admin list with course access
              if (admin.isLoading && admin.admins.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.forest)),
                  ),
                )
              else
                ...admin.admins.map((a) {
                  final email = a['email'] as String? ?? '';
                  final role = a['role'] as String? ?? 'admin';
                  final isSuper = role == 'superAdmin';
                  final allowedCourses = (a['allowedCourses'] as List?)?.cast<String>() ?? [];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
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
                                    Text(email,
                                      style: AppTheme.body(size: 13.5, color: AppColors.ink),
                                      overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isSuper ? AppColors.forestTint : AppColors.bone,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            isSuper ? 'Super Admin' : 'Admin',
                                            style: AppTheme.body(size: 10,
                                              color: isSuper ? AppColors.forest : AppColors.ink3,
                                              weight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (isSuper)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.forestTint,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'All Courses',
                                    style: AppTheme.body(size: 11, color: AppColors.forest, weight: FontWeight.w600),
                                  ),
                                ),
                            ],
                          ),
                          if (!isSuper) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final course in _allCourses)
                                  _CourseChip(
                                    label: _courseLabels[course] ?? course,
                                    assigned: allowedCourses.contains(course) || allowedCourses.contains('*'),
                                    onTap: () {
                                      _toggleCourse(email, course, allowedCourses);
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _setAllCourses(email),
                                  child: Text('Grant all',
                                    style: AppTheme.body(size: 11.5, color: AppColors.forest, weight: FontWeight.w600)
                                        .copyWith(decoration: TextDecoration.underline)),
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: () => _clearAllCourses(email),
                                  child: Text('Revoke all',
                                    style: AppTheme.body(size: 11.5, color: AppColors.clay, weight: FontWeight.w600)
                                        .copyWith(decoration: TextDecoration.underline)),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleCourse(String email, String course, List<String> current) {
    final updated = List<String>.from(current);
    if (updated.contains(course)) {
      updated.remove(course);
    } else {
      updated.add(course);
    }
    context.read<AdminProvider>().updateAdminCourses(email, updated);
  }

  void _setAllCourses(String email) {
    context.read<AdminProvider>().updateAdminCourses(email, ['*']);
  }

  void _clearAllCourses(String email) {
    context.read<AdminProvider>().updateAdminCourses(email, []);
  }
}

class _CourseChip extends StatelessWidget {
  final String label;
  final bool assigned;
  final VoidCallback onTap;

  const _CourseChip({required this.label, required this.assigned, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: assigned ? AppColors.forestTint : AppColors.bone,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: assigned ? AppColors.forest.withValues(alpha: 0.3) : AppColors.line,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.body(
            size: 11,
            color: assigned ? AppColors.forest : AppColors.ink3,
            weight: assigned ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// All available course keys
const _allCourses = [
  'soahs_ug', 'soahs_pg', 'son',
  'set_ug', 'set_pg',
  'sbm_ug', 'sbm_pg',
  'solla_ug', 'solla_pg',
  'sjmc', 'sos_ug', 'sos_pg',
  'sola', 'soe', 'sop',
];

const _courseLabels = {
  'soahs_ug': 'SOAHS UG',
  'soahs_pg': 'SOAHS PG',
  'son': 'Nursing',
  'set_ug': 'SET UG',
  'set_pg': 'SET PG',
  'sbm_ug': 'SBM UG',
  'sbm_pg': 'SBM PG',
  'solla_ug': 'Law UG',
  'solla_pg': 'Law PG',
  'sjmc': 'Journalism',
  'sos_ug': 'Science UG',
  'sos_pg': 'Science PG',
  'sola': 'Liberal Arts',
  'soe': 'Education',
  'sop': 'Pharmacy',
};
