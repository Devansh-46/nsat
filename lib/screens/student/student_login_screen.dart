import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/niu_app_bar.dart';
import '../../widgets/niu_button.dart';
import '../../widgets/info_row.dart';

class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  final TextEditingController _idController =
      TextEditingController(text: 'NIU2025MBA0472');
  bool _verified = true;

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const NiuAppBar(title: 'Student login', subtitle: 'ACCSOFT verification'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter your ACCSOFT student ID',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.primary),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _idController.text,
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 10),
                  NiuButton(
                    label: 'Verify & continue',
                    onTap: () => setState(() => _verified = true),
                  ),
                  const SizedBox(height: 20),

                  if (_verified) ...[
                    const Text(
                      'Fetched from ACCSOFT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const InfoRow(
                      dotColor: AppColors.green,
                      label: 'Student name',
                      value: 'Rahul Sharma',
                    ),
                    const InfoRow(
                      dotColor: AppColors.primary,
                      label: 'Course applied',
                      value: 'MBA — Management',
                    ),
                    const InfoRow(
                      dotColor: AppColors.green,
                      label: 'Application fee',
                      value: 'Paid — Rs.1,100 confirmed',
                    ),
                    const InfoRow(
                      dotColor: AppColors.primary,
                      label: 'Previous attempt',
                      value: 'None — eligible to attempt',
                    ),
                    const SizedBox(height: 4),
                    NiuButton(
                      label: 'Proceed to test selection',
                      variant: NiuButtonVariant.gold,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.testCategory),
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
