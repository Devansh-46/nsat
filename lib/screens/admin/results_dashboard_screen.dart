import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/niu_app_bar.dart';
import '../../widgets/niu_button.dart';
import '../../widgets/stat_card.dart';
import '../../providers/admin_provider.dart';

class ResultsDashboardScreen extends StatefulWidget {
  const ResultsDashboardScreen({super.key});

  @override
  State<ResultsDashboardScreen> createState() => _ResultsDashboardScreenState();
}

class _ResultsDashboardScreenState extends State<ResultsDashboardScreen> {
  String _selectedCourse = 'All courses';
  final List<String> _courseFilters = [
    'All courses',
    'MBA',
    'B.Tech',
    'BBA',
    'LLB',
    'B.Com'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchAllResults();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final results = provider.allResults;

    final filteredResults = _selectedCourse == 'All courses'
        ? results
        : results
            .where((r) => r.categoryName.startsWith(_selectedCourse))
            .toList();

    final totalSubmissions = filteredResults.length;
    final avgScore = totalSubmissions > 0
        ? (filteredResults.map((e) => e.netScore).reduce((a, b) => a + b) /
                totalSubmissions)
            .toStringAsFixed(1)
        : '0.0';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          NiuAppBar(
              title: 'Results dashboard',
              subtitle: '${results.length} total submissions'),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Filters
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedCourse,
                                    isExpanded: true,
                                    icon: const Icon(Icons.keyboard_arrow_down,
                                        color: AppColors.textMuted, size: 18),
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textPrimary),
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        setState(
                                            () => _selectedCourse = newValue);
                                      }
                                    },
                                    items: _courseFilters
                                        .map<DropdownMenuItem<String>>(
                                            (String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                                child: _FilterDropdown(
                                    label: 'All dates')), // Placeholder for now
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Summary stats
                        Row(
                          children: [
                            Expanded(
                                child: StatCard(
                                    value: '$totalSubmissions',
                                    label: 'Submitted')),
                            const SizedBox(width: 6),
                            Expanded(
                                child: StatCard(
                                    value: avgScore, label: 'Avg score')),
                            const SizedBox(width: 6),
                            const Expanded(
                                child: StatCard(
                                    value: '0',
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
                          child: const Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text('STUDENT ID',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textMuted,
                                    )),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('COURSE',
                                    textAlign: TextAlign.left,
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
                        if (filteredResults.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                                child: Text('No results found.',
                                    style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12))),
                          ),

                        ...filteredResults.map((session) {
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
                                  flex: 3,
                                  child: Text(
                                    session.studentId,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.primary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    session.categoryName
                                        .replaceAll(' NIU-SAT', '')
                                        .split('—')
                                        .first
                                        .trim(),
                                    textAlign: TextAlign.left,
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textMuted),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(
                                  width: 36,
                                  child: Text(
                                    session.formattedNetScore,
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
                                        color: AppColors.bgGreenLight,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Pushed',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textGreen,
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: NiuButton(
                                label: 'Retry failed',
                                variant: NiuButtonVariant.outline,
                                fontSize: 11,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
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
      height: 38,
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
