import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/niu_app_bar.dart';
import '../../widgets/niu_button.dart';
import '../../models/test_config_model.dart';
import '../../providers/admin_provider.dart';

class CreateTestScreen extends StatefulWidget {
  const CreateTestScreen({super.key});

  @override
  State<CreateTestScreen> createState() => _CreateTestScreenState();
}

class _CreateTestScreenState extends State<CreateTestScreen> {
  final TextEditingController _titleController =
      TextEditingController(text: 'NIU-SAT Entrance');
  final TextEditingController _qCountController =
      TextEditingController(text: '60');
  final TextEditingController _durationController =
      TextEditingController(text: '60');
  final TextEditingController _marksController =
      TextEditingController(text: '1.0');
  final TextEditingController _startDateController =
      TextEditingController(text: '15-Jun-2025');

  String _selectedCategory = 'MBA — Management';
  bool _dropdownOpen = false;

  bool _negativeMarking = true;
  bool _published = false;

  final List<String> _categories = [
    'B.Tech / Engineering',
    'MBA — Management',
    'BBA',
    'B.Com',
    'LLB',
    'B.Sc',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _qCountController.dispose();
    _durationController.dispose();
    _marksController.dispose();
    _startDateController.dispose();
    super.dispose();
  }

  void _saveTest() async {
    final provider = context.read<AdminProvider>();

    final config = TestConfigModel(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text,
      category: _selectedCategory,
      questionCount: int.tryParse(_qCountController.text) ?? 60,
      durationMinutes: int.tryParse(_durationController.text) ?? 60,
      marksPerQuestion: double.tryParse(_marksController.text) ?? 1.0,
      negativeMarking: _negativeMarking,
      negativeMarksPerWrong: 0.25,
      startDate: _startDateController.text,
      isPublished: _published,
    );

    final success = await provider.createTest(config);
    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

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
                  if (provider.error != null) ...[
                    Text(
                      provider.error!,
                      style:
                          const TextStyle(color: AppColors.red, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Test title
                  _TextInputField(
                    label: 'Test title',
                    controller: _titleController,
                    highlighted: true,
                  ),
                  const SizedBox(height: 10),

                  // Course category
                  const _FormLabel(text: 'Course category'),
                  const SizedBox(height: 3),
                  GestureDetector(
                    onTap: () => setState(() => _dropdownOpen = !_dropdownOpen),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(7),
                        color: Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_selectedCategory,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textPrimary)),
                          Icon(
                              _dropdownOpen
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: AppColors.textMuted,
                              size: 18),
                        ],
                      ),
                    ),
                  ),

                  // Dropdown options
                  if (_dropdownOpen) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        border: Border.all(color: AppColors.borderLight),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _categories.map((c) {
                          final selected = c == _selectedCategory;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = c;
                                _dropdownOpen = false;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Text(
                                selected ? '$c  (selected)' : c,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  fontWeight: selected
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Two-column fields
                  Row(
                    children: [
                      Expanded(
                          child: _TextInputField(
                              label: 'No. of questions',
                              controller: _qCountController,
                              isNumber: true)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _TextInputField(
                              label: 'Duration (mins)',
                              controller: _durationController,
                              isNumber: true)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                          child: _TextInputField(
                              label: 'Marks per Q',
                              controller: _marksController,
                              isNumber: true)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _TextInputField(
                              label: 'Start date',
                              controller: _startDateController)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Negative marking toggle
                  _ToggleRow(
                    label: 'Negative marking',
                    subtitle: '-0.25 per wrong answer',
                    value: _negativeMarking,
                    onChanged: (v) => setState(() => _negativeMarking = v),
                  ),

                  // Published toggle
                  _ToggleRow(
                    label: 'Active / published',
                    subtitle: 'Students can see this test',
                    value: _published,
                    onChanged: (v) => setState(() => _published = v),
                  ),
                  const SizedBox(height: 14),

                  if (provider.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    NiuButton(
                      label: 'Save test',
                      onTap: _saveTest,
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

class _TextInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool highlighted;
  final bool isNumber;

  const _TextInputField({
    required this.label,
    required this.controller,
    this.highlighted = false,
    this.isNumber = false,
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
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            border: Border.all(
                color: highlighted ? AppColors.primary : AppColors.border),
            borderRadius: BorderRadius.circular(7),
          ),
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
            decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10)),
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
            bottom: BorderSide(color: AppColors.borderLight, width: 0.5)),
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
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
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
