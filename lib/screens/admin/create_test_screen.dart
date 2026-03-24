import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/niu_app_bar.dart';
import '../../widgets/niu_button.dart';

class CreateTestScreen extends StatefulWidget {
  const CreateTestScreen({super.key});

  @override
  State<CreateTestScreen> createState() => _CreateTestScreenState();
}

class _CreateTestScreenState extends State<CreateTestScreen> {
  bool _negativeMarking = true;
  bool _published = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const NiuAppBar(title: 'Create test', subtitle: 'New NIU-SAT paper'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Test title
                  _FormField(
                    label: 'Test title',
                    value: 'NIU-SAT MBA — June 2025',
                    highlighted: true,
                  ),
                  const SizedBox(height: 10),

                  // Course category
                  const _FormLabel(text: 'Course category'),
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
                        Text('MBA — Management',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary)),
                        Icon(Icons.keyboard_arrow_down,
                            color: AppColors.textMuted, size: 18),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Two-column fields
                  Row(
                    children: [
                      Expanded(
                          child: _FormField(
                              label: 'No. of questions', value: '60')),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _FormField(
                              label: 'Duration (mins)', value: '60')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                          child:
                              _FormField(label: 'Marks per Q', value: '1')),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _FormField(
                              label: 'Start date', value: '15-Jun-2025')),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Negative marking toggle
                  _ToggleRow(
                    label: 'Negative marking',
                    subtitle: '-0.25 per wrong answer',
                    value: _negativeMarking,
                    onChanged: (v) =>
                        setState(() => _negativeMarking = v),
                  ),

                  // Published toggle
                  _ToggleRow(
                    label: 'Active / published',
                    subtitle: 'Students can see this test',
                    value: _published,
                    onChanged: (v) => setState(() => _published = v),
                  ),
                  const SizedBox(height: 14),

                  NiuButton(
                    label: 'Save & publish test',
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 8),
                  NiuButton(
                    label: 'Preview before publishing',
                    variant: NiuButtonVariant.outline,
                    fontSize: 11,
                    padding: const EdgeInsets.symmetric(vertical: 10),
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

class _FormField extends StatelessWidget {
  final String label;
  final String value;
  final bool highlighted;

  const _FormField({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FormLabel(text: label),
        const SizedBox(height: 3),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            border: Border.all(
                color: highlighted ? AppColors.primary : AppColors.border),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            value,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(
        border: Border(
            bottom:
                BorderSide(color: AppColors.borderLight, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textPrimary)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 38,
              height: 22,
              decoration: BoxDecoration(
                color: value ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(11),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 18,
                  height: 18,
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
