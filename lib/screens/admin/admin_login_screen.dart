import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/mesh_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/niu_field.dart';
import '../../widgets/niu_button.dart';

/// Admin login — Verdant Daylight reskin. Logic unchanged.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    final provider = context.read<AuthProvider>();
    final ok = await provider.adminLogin(
        _emailController.text, _passwordController.text);
    if (ok && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuthProvider>();
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: MeshBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(22, topPad > 0 ? 12 : 28, 22, 32),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.forest,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x332C6B42),
                        offset: Offset(0, 8),
                        blurRadius: 22,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.shield_outlined,
                      size: 28, color: Colors.white),
                ),
                const SizedBox(height: 14),
                Text.rich(
                  TextSpan(
                    text: 'Admin ',
                    style: AppTheme.displaySm(size: 22),
                    children: [AppTheme.italicSpan('sign in.')],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'NIU examination team only',
                  style: AppTheme.body(size: 12.5, color: AppColors.ink4),
                ),
                const SizedBox(height: 24),

                GlassCard(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      NiuField(
                        label: 'Admin email',
                        icon: Icons.email_outlined,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      NiuField(
                        label: 'Password',
                        icon: Icons.lock_outline,
                        controller: _passwordController,
                        obscureText: true,
                      ),
                      const SizedBox(height: 20),
                      if (provider.error != null) ...[
                        Text(
                          provider.error!,
                          style: AppTheme.body(size: 12.5, color: AppColors.clay),
                        ),
                        const SizedBox(height: 12),
                      ],
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
                        NiuButton(label: 'Sign in', onTap: _login),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}