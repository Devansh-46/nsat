import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/niu_app_bar.dart';
import '../../widgets/niu_button.dart';
import '../../providers/admin_provider.dart';

class PushNotificationScreen extends StatefulWidget {
  const PushNotificationScreen({super.key});

  @override
  State<PushNotificationScreen> createState() => _PushNotificationScreenState();
}

class _PushNotificationScreenState extends State<PushNotificationScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  
  bool _scheduleLater = false;
  String _selectedCategory = 'All';

  final List<String> _categories = ['All', 'MBA', 'B.Tech', 'BBA', 'LLB', 'B.Com'];

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

  void _sendNotification() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter title and message body')));
      return;
    }

    final provider = context.read<AdminProvider>();
    final success = await provider.sendNotification(
      _titleController.text, 
      _bodyController.text, 
      _selectedCategory, 
      _scheduleLater
    );

    if (success && mounted) {
      _titleController.clear();
      _bodyController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.successMessage ?? 'Sent successfully'), backgroundColor: AppColors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const NiuAppBar(
              title: 'Send notification', subtitle: 'Firebase push (FCM)'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   if (provider.error != null) ...[
                    Text(
                      provider.error!,
                      style: const TextStyle(color: AppColors.red, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Notification form card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FormLabel(text: 'Notification title'),
                        const SizedBox(height: 3),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: AppColors.primary),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: TextField(
                            controller: _titleController,
                            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'e.g. MBA test starts in 2 hours',
                              hintStyle: TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const _FormLabel(text: 'Message body'),
                        const SizedBox(height: 3),
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(minHeight: 56),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: TextField(
                            controller: _bodyController,
                            maxLines: 4,
                            minLines: 2,
                            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.5),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Dear student...',
                              hintStyle: TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category filter
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Filter target users',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _categories.map((cat) {
                            final isSelected = cat == _selectedCategory;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedCategory = cat),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : const Color(0xFFE6F1FB),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  cat,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF0C447C),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Schedule toggle
                  Container(
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Schedule for later',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textPrimary)),
                              Text('Set date & time',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _scheduleLater = !_scheduleLater),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 38,
                            height: 22,
                            decoration: BoxDecoration(
                              color: _scheduleLater
                                  ? AppColors.primary
                                  : AppColors.border,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: AnimatedAlign(
                              duration: const Duration(milliseconds: 200),
                              alignment: _scheduleLater
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                width: 18,
                                height: 18,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 2),
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
                  ),
                  const SizedBox(height: 12),

                  if (provider.isLoading)
                     const Center(child: CircularProgressIndicator())
                  else
                    NiuButton(
                      label: _scheduleLater ? 'Schedule notification' : 'Send notification now',
                      onTap: _sendNotification,
                    ),
                  const SizedBox(height: 16),
                  
                  if (provider.notifications.isNotEmpty) ...[
                     const Padding(
                       padding: EdgeInsets.only(bottom: 8.0, top: 4.0),
                       child: Text('Recent Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                     ),
                     ...provider.notifications.take(3).map((n) => Container(
                       margin: const EdgeInsets.only(bottom: 8),
                       padding: const EdgeInsets.all(10),
                       decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(6)),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(n.title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11)),
                           Text('${n.deliveredCount} delivered to ${n.targetCategory}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                         ],
                       ),
                     )),
                  ] else ...[
                     const Center(
                      child: Text(
                        'No notifications sent yet.',
                        style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                        textAlign: TextAlign.center,
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

class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        color: AppColors.textMuted,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
