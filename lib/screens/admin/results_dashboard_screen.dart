import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../services/results_exporter.dart';
import '../../widgets/glass_card.dart';

/// Admin results dashboard — Verdant Daylight reskin.
/// Real Firestore results via AdminProvider.
class ResultsDashboardScreen extends StatefulWidget {
  const ResultsDashboardScreen({super.key});

  @override
  State<ResultsDashboardScreen> createState() =>
      _ResultsDashboardScreenState();
}

class _ResultsDashboardScreenState extends State<ResultsDashboardScreen> {
  String _courseFilter = 'All';
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchAllResults();
    });
  }

  Future<void> _exportCsv(List results) async {
    setState(() => _exporting = true);
    final result = await ResultsExporter.export(List.from(results));
    if (!mounted) return;
    setState(() => _exporting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor:
            result.success ? AppColors.forest : AppColors.clay,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final all = provider.allResults;

    final courses = <String>{'All', ...all.map((r) => r.course)};
    final filtered = _courseFilter == 'All'
        ? all
        : all.where((r) => r.course == _courseFilter).toList();

    final total = filtered.length;
    final avg = total > 0
        ? (filtered.map((r) => r.netScore).reduce((a, b) => a + b) / total)
            .toStringAsFixed(1)
        : '0.0';

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
              child: Row(
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
                      child: const Icon(Icons.chevron_left,
                          size: 20, color: AppColors.ink3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Results', style: AppTheme.displaySm(size: 18)),
                        Text(
                          '${all.length} total submissions',
                          style: AppTheme.body(
                              size: 11.5, color: AppColors.ink4),
                        ),
                      ],
                    ),
                  ),
                  // Export
                  GestureDetector(
                    onTap: (_exporting || all.isEmpty)
                        ? null
                        : () => _exportCsv(all),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: all.isEmpty
                            ? AppColors.bone
                            : AppColors.forest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _exporting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              children: [
                                Icon(
                                  Icons.download_outlined,
                                  size: 15,
                                  color: all.isEmpty
                                      ? AppColors.ink4
                                      : Colors.white,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Export',
                                  style: AppTheme.body(
                                    size: 12,
                                    color: all.isEmpty
                                        ? AppColors.ink4
                                        : Colors.white,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: provider.isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.forest,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Summary stats
                          Row(
                            children: [
                              Expanded(
                                child: _MiniStat(
                                    value: '$total', label: 'Submitted'),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _MiniStat(
                                    value: avg, label: 'Avg net score'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Course chips
                          if (courses.length > 1) ...[
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: courses.map((c) {
                                final selected = c == _courseFilter;
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _courseFilter = c),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppColors.forest
                                          : AppColors.bone,
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      border: Border.all(
                                        color: selected
                                            ? AppColors.forest
                                            : AppColors.line,
                                      ),
                                    ),
                                    child: Text(
                                      c == 'All'
                                          ? 'All'
                                          : c.toUpperCase(),
                                      style: AppTheme.body(
                                        size: 11,
                                        color: selected
                                            ? Colors.white
                                            : AppColors.ink3,
                                        weight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Results list
                          if (filtered.isEmpty)
                            GlassCard(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 22, vertical: 32),
                              blurEnabled: false,
                              child: Column(
                                children: [
                                  const Icon(Icons.inbox_outlined,
                                      size: 34, color: AppColors.ink4),
                                  const SizedBox(height: 12),
                                  Text('No results yet',
                                      style: AppTheme.displaySm(size: 15)),
                                ],
                              ),
                            )
                          else
                            GlassCard(
                              padding: EdgeInsets.zero,
                              blurEnabled: false,
                              child: Column(
                                children: [
                                  for (int i = 0;
                                      i < filtered.length;
                                      i++) ...[
                                    _ResultRow(
                                      name: filtered[i].studentName,
                                      niuId: filtered[i].applicationNo,
                                      course: filtered[i].course,
                                      net: filtered[i].netScore,
                                      max: filtered[i].maxScore,
                                    ),
                                    if (i < filtered.length - 1)
                                      Container(
                                        height: 0.5,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 14),
                                        color: AppColors.line2,
                                      ),
                                  ],
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  const _MiniStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      radius: 14,
      blurEnabled: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTheme.mono(size: 24, color: AppColors.forest)),
          const SizedBox(height: 1),
          Text(label, style: AppTheme.body(size: 11.5, color: AppColors.ink4)),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String name;
  final String niuId;
  final String course;
  final double net;
  final double max;

  const _ResultRow({
    required this.name,
    required this.niuId,
    required this.course,
    required this.net,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? '(no name)' : name,
                  style: AppTheme.body(
                    size: 13.5,
                    color: AppColors.ink,
                    weight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$niuId  ·  ${course.toUpperCase()}',
                  style: AppTheme.mono(size: 10.5, color: AppColors.ink4),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.forestTint,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${net.toStringAsFixed(2)} / ${max.toStringAsFixed(0)}',
              style: AppTheme.mono(size: 11, color: AppColors.forest),
            ),
          ),
        ],
      ),
    );
  }
}