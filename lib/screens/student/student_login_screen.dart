import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/niu_app_bar.dart';
import '../../widgets/niu_button.dart';
import '../../widgets/info_row.dart';
import '../../providers/auth_provider.dart';

class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  final TextEditingController _idController =
      TextEditingController(text: 'NIU2025MBA0472');
  bool _verified = false;

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  void _verify() async {
    final provider = context.read<AuthProvider>();
    final success = await provider.studentLogin(_idController.text);
    if (success && mounted) {
      setState(() => _verified = true);
    }
  }

  void _proceed(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    if (!user.feePaid) {
      Navigator.pushNamed(context, AppRoutes.feeGate);
    } else {
      Navigator.pushNamed(context, AppRoutes.testCategory);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuthProvider>();
    final user = provider.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const NiuAppBar(
              title: 'Student login', subtitle: 'ACCSOFT verification'),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.primary),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _idController,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                      onChanged: (v) {
                        if (_verified) setState(() => _verified = false);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (provider.error != null) ...[
                    Text(
                      provider.error!,
                      style:
                          const TextStyle(color: AppColors.red, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (provider.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (!_verified)
                    NiuButton(
                      label: 'Verify & continue',
                      onTap: _verify,
                    ),
                  const SizedBox(height: 20),
                  if (_verified && user != null) ...[
                    const Text(
                      'Fetched from ACCSOFT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InfoRow(
                      dotColor: AppColors.green,
                      label: 'Student name',
                      value: user.name,
                    ),
                    InfoRow(
                      dotColor: AppColors.primary,
                      label: 'Course applied',
                      value: user.course ?? 'N/A',
                    ),
                    InfoRow(
                      dotColor: user.feePaid ? AppColors.green : AppColors.red,
                      label: 'Application fee',
                      value: user.feeStatusText,
                    ),
                    InfoRow(
                      dotColor:
                          user.hasAttempted ? AppColors.red : AppColors.primary,
                      label: 'Previous attempt',
                      value: user.attemptStatusText,
                    ),
                    const SizedBox(height: 4),
                    NiuButton(
                      label: 'Proceed to test selection',
                      variant: NiuButtonVariant.gold,
                      onTap: () => _proceed(context),
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
