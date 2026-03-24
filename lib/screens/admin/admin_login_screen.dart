import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/niu_app_bar.dart';
import '../../widgets/niu_button.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _emailController =
      TextEditingController(text: 'admin@niu.edu.in');
  final TextEditingController _passwordController =
      TextEditingController(text: 'admin123');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    final provider = context.read<AuthProvider>();
    final success = await provider.adminLogin(
        _emailController.text, _passwordController.text);
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const NiuAppBar(
              title: 'Admin login', subtitle: 'NIU examination team'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Admin Email',
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
                      controller: _emailController,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textPrimary),
                      decoration:
                          const InputDecoration(border: InputBorder.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Password',
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
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textPrimary),
                      decoration:
                          const InputDecoration(border: InputBorder.none),
                    ),
                  ),
                  const SizedBox(height: 20),
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
                  else
                    NiuButton(
                      label: 'Sign in',
                      onTap: _login,
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
