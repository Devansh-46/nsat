import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../models/app_log_model.dart';
import '../../widgets/mesh_background.dart';
import '../../widgets/glass_card.dart';

class AdminLogsScreen extends StatefulWidget {
  const AdminLogsScreen({super.key});

  @override
  State<AdminLogsScreen> createState() => _AdminLogsScreenState();
}

class _AdminLogsScreenState extends State<AdminLogsScreen> {
  String _filterLevel = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final topPad = MediaQuery.of(context).padding.top;

    List<AppLogModel> logs = admin.logs;
    if (_filterLevel != 'All') {
      logs = logs.where((l) => l.level.toLowerCase() == _filterLevel.toLowerCase()).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: MeshBackground(
        child: Column(
          children: [
            SizedBox(height: topPad + 12),
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildFilters(),
            const SizedBox(height: 16),
            Expanded(
              child: admin.isLoading && admin.logs.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.forest))
                  : logs.isEmpty
                      ? Center(
                          child: Text('No logs found',
                              style: AppTheme.body(color: AppColors.ink4)))
                      : RefreshIndicator(
                          color: AppColors.forest,
                          onRefresh: () => admin.fetchLogs(),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(22, 0, 22, 32),
                            itemCount: logs.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return _LogTile(log: logs[index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.ink),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text('System Logs', style: AppTheme.displaySm(size: 20)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.ink),
            onPressed: () => context.read<AdminProvider>().fetchLogs(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ['All', 'Error', 'Info', 'Debug'].map((level) {
            final isSelected = _filterLevel == level;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _filterLevel = level),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.forest : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.forest : AppColors.ink4,
                    ),
                  ),
                  child: Text(
                    level,
                    style: AppTheme.displaySm(
                      size: 13,
                      color: isSelected ? Colors.white : AppColors.ink,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _LogTile extends StatefulWidget {
  final AppLogModel log;

  const _LogTile({required this.log});

  @override
  State<_LogTile> createState() => _LogTileState();
}

class _LogTileState extends State<_LogTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l = widget.log;
    final isError = l.level.toLowerCase() == 'error';
    final hasDetails = l.error != null || l.stackTrace != null;

    final badgeColor = isError ? Colors.red : AppColors.forest;
    final badgeBg = isError ? Colors.red.withValues(alpha: 0.1) : AppColors.forestTint;
    
    final timeStr = l.timestamp != null 
        ? DateFormat('MMM d, HH:mm:ss').format(l.timestamp!)
        : 'Unknown time';

    return GlassCard(
      padding: const EdgeInsets.all(16),
      radius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  l.level.toUpperCase(),
                  style: AppTheme.mono(size: 10, color: badgeColor),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  timeStr,
                  style: AppTheme.body(size: 12, color: AppColors.ink4),
                ),
              ),
              if (l.requestId != null)
                Text(
                  'req:${l.requestId}',
                  style: AppTheme.mono(size: 10, color: AppColors.ink4),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '[${l.tag}] ${l.message}',
            style: AppTheme.displaySm(size: 14, color: AppColors.ink),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: AppColors.ink4),
              const SizedBox(width: 4),
              Text(
                l.userId,
                style: AppTheme.body(size: 12, color: AppColors.ink4),
              ),
              const Spacer(),
              if (hasDetails)
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Row(
                    children: [
                      Text(
                        _expanded ? 'Hide details' : 'Show details',
                        style: AppTheme.displaySm(size: 12, color: AppColors.forest),
                      ),
                      Icon(
                        _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 16,
                        color: AppColors.forest,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (_expanded && hasDetails) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (l.error != null) ...[
                    Text('Error:', style: AppTheme.displaySm(size: 12)),
                    const SizedBox(height: 4),
                    Text(l.error!, style: AppTheme.mono(size: 11, color: Colors.red.shade700)),
                  ],
                  if (l.stackTrace != null) ...[
                    const SizedBox(height: 12),
                    Text('Stack Trace:', style: AppTheme.displaySm(size: 12)),
                    const SizedBox(height: 4),
                    Text(l.stackTrace!, style: AppTheme.mono(size: 10, color: AppColors.ink4)),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
