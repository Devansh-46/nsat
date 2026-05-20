import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/eyebrow.dart';
import '../../widgets/niu_field.dart';
import '../../widgets/niu_button.dart';
import '../../widgets/note_box.dart';

/// Send notification — Verdant Daylight reskin. Mock send (Phase 1).
class PushNotificationScreen extends StatefulWidget {
  const PushNotificationScreen({super.key});

  @override
  State<PushNotificationScreen> createState() =>
      _PushNotificationScreenState();
}

class _PushNotificationScreenState extends State<PushNotificationScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchNotifications();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _send() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a title and message body')),
      );
      return;
    }
    final provider = context.read<AdminProvider>();
    final ok = await provider.sendNotification(
        _titleController.text, _bodyController.text, 'All', false);
    if (ok && mounted) {
      _titleController.clear();
      _bodyController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.successMessage ?? 'Sent'),
          backgroundColor: AppColors.forest,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

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
                  Text('Send notification',
                      style: AppTheme.displaySm(size: 18)),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const NoteBox.gold(
                      icon: Icons.info_outline,
                      body: 'Push delivery is not active in this '
                          'build. Messages are recorded but not '
                          'yet sent to devices.',
                    ),
                    const SizedBox(height: 16),

                    // Compose card
                    GlassCard(
                      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          NiuField(
                            label: 'Title',
                            hint: 'e.g. Test starts in 2 hours',
                            controller: _titleController,
                          ),
                          const SizedBox(height: 16),
                          // Message — using a manual glass field for
                          // multi-line since NiuField is single-line.
                          const Eyebrow('Message'),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              gradient: AppColors.glassBg,
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: AppColors.glassBorder),
                            ),
                            child: TextField(
                              controller: _bodyController,
                              maxLines: 4,
                              style: AppTheme.body(
                                  size: 14, color: AppColors.ink),
                              cursorColor: AppColors.forest,
                              decoration: InputDecoration(
                                hintText: 'Dear student...',
                                hintStyle: AppTheme.body(
                                    size: 14, color: AppColors.ink4),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (provider.isLoading)
                            const SizedBox(
                              height: 48,
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
                          else
                            NiuButton(
                              label: 'Send notification',
                              variant: NiuButtonVariant.forest,
                              onTap: _send,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (provider.notifications.isNotEmpty) ...[
                      const Eyebrow('recent'),
                      const SizedBox(height: 10),
                      ...provider.notifications.take(5).map(
                            (n) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: GlassCard(
                                padding: const EdgeInsets.all(14),
                                radius: 14,
                                blurEnabled: false,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      n.title,
                                      style: AppTheme.body(
                                        size: 13,
                                        color: AppColors.ink,
                                        weight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      n.body,
                                      style: AppTheme.body(
                                          size: 12, color: AppColors.ink3),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                    ],
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