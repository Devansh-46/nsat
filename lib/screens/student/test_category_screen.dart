import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/niu_app_bar.dart';
import '../../widgets/niu_button.dart';

class TestCategoryScreen extends StatefulWidget {
  const TestCategoryScreen({super.key});

  @override
  State<TestCategoryScreen> createState() => _TestCategoryScreenState();
}

class _TestCategoryScreenState extends State<TestCategoryScreen> {
  String _selectedCourse = 'MBA — Management';
  bool _dropdownOpen = false;

  final List<String> _courses = [
    'B.Tech / Engineering',
    'MBA — Management',
    'BBA',
    'B.Com',
    'LLB',
    'B.Sc',
    'B.Ed / MCA / BA...',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const NiuAppBar(title: 'Select test category', subtitle: 'Hello, Rahul Sharma'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select your subject / program',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Dropdown
                  GestureDetector(
                    onTap: () => setState(() => _dropdownOpen = !_dropdownOpen),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedCourse,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textPrimary),
                          ),
                          Icon(
                            _dropdownOpen
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
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
                        children: _courses.map((c) {
                          final selected = c == _selectedCourse;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCourse = c;
                                _dropdownOpen = false;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                selected ? '$c  (selected)' : c,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  fontWeight:
                                      selected ? FontWeight.w500 : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Text(
                    'Test details',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Test details grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 2.2,
                    children: const [
                      _DetailCard(value: '60', label: 'Questions'),
                      _DetailCard(value: '60', label: 'Minutes'),
                      _DetailCard(value: '1', label: 'Mark per Q'),
                      _DetailCard(value: '-0.25', label: 'Wrong ans.'),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Warning
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.bgGoldLight,
                      border: Border.all(color: AppColors.borderGold),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'One attempt only. The test cannot be retaken once started.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textGold,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  NiuButton(
                    label: 'Start test',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.liveTest),
                  ),
                  const SizedBox(height: 8),
                  NiuButton(
                    label: 'Download brochure',
                    variant: NiuButtonVariant.outline,
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

class _DetailCard extends StatelessWidget {
  final String value;
  final String label;

  const _DetailCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: Border.all(color: AppColors.borderLight, width: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
