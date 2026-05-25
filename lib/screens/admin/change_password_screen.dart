import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/eyebrow.dart';
import '../../widgets/niu_field.dart';
import '../../widgets/niu_button.dart';
import '../../widgets/note_box.dart';
import '../../routes/app_routes.dart';

/// Force password change screen — shown after first login for newly
/// created admin accounts.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _pass1Controller = TextEditingController();
  final _pass2Controller = TextEditingController();
  bool _pass1Valid = false;
  bool _pass2Valid = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().clearError();
    });
  }

  @override
  void dispose() {
    _pass1Controller.dispose();
    _pass2Controller.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final pass1 = _pass1Controller.text;
    final pass2 = _pass2Controller.text;

    if (pass1.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }
    if (pass1 != pass2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.changePassword(pass1);
    if (ok && mounted) {
      // Navigate to admin dashboard
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.adminDashboard,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(22, topPad > 0 ? 12 : 48, 22, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Eyebrow('security'),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  text: 'Set your ',
                  style: AppTheme.display(size: 26),
                  children: [AppTheme.italicSpan('password.')],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'You must create a new password before accessing the dashboard. '
                'Your temporary password will expire after this change.',
                style: AppTheme.body(size: 12.5, color: AppColors.ink4),
              ),
              const SizedBox(height: 24),

              NoteBox.gold(
                icon: Icons.info_outlined,
                title: 'Why am I seeing this?',
                body: 'Your admin account was created with a temporary password. '
                    'For security, you must set your own password before signing in.',
              ),
              const SizedBox(height: 16),

              GlassCard(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NiuField(
                      label: 'New password',
                      hint: 'Min 6 characters',
                      icon: Icons.lock_outlined,
                      controller: _pass1Controller,
                      obscureText: true,
                      onChanged: (val) {
                        setState(() => _pass1Valid = val.trim().length >= 6);
                      },
                    ),
                    const SizedBox(height: 12),
                    NiuField(
                      label: 'Confirm password',
                      hint: 'Re-enter password',
                      icon: Icons.lock_outline,
                      controller: _pass2Controller,
                      obscureText: true,
                      onChanged: (val) {
                        setState(() => _pass2Valid = val.trim().length >= 6);
                      },
                      onSubmitted: (_) {
                        if (_pass1Valid && _pass2Valid) _changePassword();
                      },
                    ),
                    if (auth.error != null) ...[
                      const SizedBox(height: 10),
                      NoteBox.clay(icon: Icons.error_outline, body: auth.error!),
                    ],
                    const SizedBox(height: 16),
                    auth.isLoading
                        ? const SizedBox(
                            height: 48,
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: AppColors.forest),
                              ),
                            ),
                          )
                        : NiuButton(
                            label: 'Set password & continue',
                            variant: NiuButtonVariant.forest,
                            showArrow: true,
                            onTap: (_pass1Valid && _pass2Valid) ? _changePassword : null,
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
