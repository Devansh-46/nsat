import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../providers/admin_provider.dart';
import '../../services/results_exporter.dart';

/// Admin results dashboard — deep-forest styling. Reads the real
/// `results` Firestore collection via AdminProvider.
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
            result.success ? AppColors.green : AppColors.red,
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
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // --- Header ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(Icons.chevron_left,
                          size: 20, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Results',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${all.length} total submissions',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Export to CSV.
                  GestureDetector(
                    onTap: (_exporting || all.isEmpty)
                        ? null
                        : () => _exportCsv(all),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: all.isEmpty
                            ? AppColors.bgCard
                            : AppColors.primary,
                        borderRadius: BorderRadius.circular(9),
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
                                      ? AppColors.textMuted
                                      : Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Export',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: all.isEmpty
                                        ? AppColors.textMuted
                                        : Colors.white,
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
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Summary stats.
                          Row(
                            children: [
                              Expanded(
                                child: _MiniStat(
                                  value: '$total',
                                  label: 'Submitted',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _MiniStat(
                                  value: avg,
                                  label: 'Avg net score',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Course filter chips.
                          if (courses.length > 1) ...[
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: courses.map((c) {
                                final selected = c == _courseFilter;
                                return GestureDetector(
                                  onTap: () => setState(
                                      () => _courseFilter = c),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppColors.primary
                                          : Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      border: Border.all(
                                        color: selected
                                            ? AppColors.primary
                                            : AppColors.border,
                                      ),
                                    ),
                                    child: Text(
                                      c == 'All'
                                          ? 'All'
                                          : c.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: selected
                                            ? Colors.white
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Results list.
                          if (filtered.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(28),
                              decoration: _cardDecoration(),
                              child: const Column(
                                children: [
                                  Icon(Icons.inbox_outlined,
                                      size: 34,
                                      color: AppColors.textMuted),
                                  SizedBox(height: 10),
                                  Text(
                                    'No results yet',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              decoration: _cardDecoration(),
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
                                        color: AppColors.borderLight,
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

  static BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;

  const _MiniStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? '(no name)' : name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  '$niuId  ·  ${course.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.bgGreenLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${net.toStringAsFixed(2)} / ${max.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}