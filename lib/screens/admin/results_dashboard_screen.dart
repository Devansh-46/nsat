import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/niu_app_bar.dart';
import '../../widgets/niu_button.dart';
import '../../widgets/stat_card.dart';

class ResultsDashboardScreen extends StatelessWidget {
  const ResultsDashboardScreen({super.key});

  static const List<_ResultEntry> _entries = [
    _ResultEntry('NIU2025MBA0472', 'MBA', '39.5', true),
    _ResultEntry('NIU2025BT0183', 'B.Tech', '44.0', true),
    _ResultEntry('NIU2025LLB0091', 'LLB', '51.0', true),
    _ResultEntry('NIU2025MBA0513', 'MBA', '28.75', false),
    _ResultEntry('NIU2025BBA0044', 'BBA', '36.25', true),
    _ResultEntry('NIU2025BCM0207', 'B.Com', '42.0', true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const NiuAppBar(
              title: 'Results dashboard',
              subtitle: '1,842 total submissions'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filters
                  Row(
                    children: [
                      Expanded(child: _FilterDropdown(label: 'All courses')),
                      const SizedBox(width: 8),
                      Expanded(child: _FilterDropdown(label: 'All dates')),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Summary stats
                  Row(
                    children: const [
                      Expanded(
                          child: StatCard(value: '1842', label: 'Submitted')),
                      SizedBox(width: 6),
                      Expanded(
                          child: StatCard(value: '38.4', label: 'Avg score')),
                      SizedBox(width: 6),
                      Expanded(
                          child: StatCard(
                              value: '12',
                              label: 'Push failed',
                              valueColor: AppColors.red)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Table header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.borderLight),
                      ),
                    ),
                    child: Row(
                      children: const [
                        Expanded(
                          child: Text('ACCSOFT ID',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMuted,
                              )),
                        ),
                        SizedBox(
                          width: 44,
                          child: Text('COURSE',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMuted,
                              )),
                        ),
                        SizedBox(
                          width: 36,
                          child: Text('SCORE',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMuted,
                              )),
                        ),
                        SizedBox(
                          width: 54,
                          child: Text('STATUS',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMuted,
                              )),
                        ),
                      ],
                    ),
                  ),

                  // Table rows
                  ...List.generate(_entries.length, (i) {
                    final e = _entries[i];
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                              color: AppColors.borderLight, width: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.id,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(
                            width: 44,
                            child: Text(
                              e.course,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted),
                            ),
                          ),
                          SizedBox(
                            width: 36,
                            child: Text(
                              e.score,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 54,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: e.pushed
                                      ? AppColors.bgGreenLight
                                      : AppColors.bgRedLight,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  e.pushed ? 'Pushed' : 'Failed',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                    color: e.pushed
                                        ? AppColors.textGreen
                                        : AppColors.textRed,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: NiuButton(
                          label: 'Export CSV',
                          variant: NiuButtonVariant.outline,
                          fontSize: 11,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: NiuButton(
                          label: 'Retry failed',
                          variant: NiuButtonVariant.outline,
                          fontSize: 11,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  const _FilterDropdown({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11)),
          const Icon(Icons.keyboard_arrow_down,
              color: AppColors.textMuted, size: 18),
        ],
      ),
    );
  }
}

class _ResultEntry {
  final String id;
  final String course;
  final String score;
  final bool pushed;

  const _ResultEntry(this.id, this.course, this.score, this.pushed);
}
