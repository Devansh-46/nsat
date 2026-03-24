import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/niu_app_bar.dart';
import '../../widgets/niu_button.dart';

class PushNotificationScreen extends StatefulWidget {
  const PushNotificationScreen({super.key});

  @override
  State<PushNotificationScreen> createState() => _PushNotificationScreenState();
}

class _PushNotificationScreenState extends State<PushNotificationScreen> {
  bool _scheduleLater = false;
  String _selectedCategory = 'MBA';

  final List<String> _categories = ['MBA', 'B.Tech', 'BBA', 'LLB', 'B.Com'];

  @override
  Widget build(BuildContext context) {
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 9),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: AppColors.primary),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Text(
                            'MBA test starts in 2 hours',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const _FormLabel(text: 'Message body'),
                        const SizedBox(height: 3),
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(minHeight: 56),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Text(
                            'Dear student, your NIU-SAT for MBA begins at 10:00 AM today. Ensure you are ready.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Send to
                  const _FormLabel(text: 'Send to'),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('All students (1,842 devices)',
                            style: TextStyle(fontSize: 12)),
                        Icon(Icons.keyboard_arrow_down,
                            color: AppColors.textMuted, size: 18),
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
                          'Or filter by category',
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
                              child: Container(
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

                  NiuButton(
                    label: 'Send notification now',
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      'Previous: "Test reminder sent" — 1,820 delivered, 22 failed',
                      style: TextStyle(
                          fontSize: 10, color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
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
