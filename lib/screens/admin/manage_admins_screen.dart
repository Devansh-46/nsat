import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/eyebrow.dart';
import '../../widgets/niu_field.dart';
import '../../widgets/niu_button.dart';
import '../../widgets/note_box.dart';

class ManageAdminsScreen extends StatefulWidget {
  const ManageAdminsScreen({super.key});

  @override
  State<ManageAdminsScreen> createState() => _ManageAdminsScreenState();
}

class _ManageAdminsScreenState extends State<ManageAdminsScreen> {
  final _emailController = TextEditingController();
  bool _emailValid = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().clearMessages();
      context.read<AdminProvider>().fetchAdmins();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _addAdmin() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    final provider = context.read<AdminProvider>();
    final ok = await provider.addAdmin(email);
    if (ok && mounted) {
      _emailController.clear();
      setState(() => _emailValid = false);
      // Show dialog informing about email
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.forest,
          content: Text(
            'Login credentials emailed to $email',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _removeAdmin(String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.ivory,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Remove admin?', style: AppTheme.displaySm(size: 18)),
        content: Text(
          'Revoke admin access for $email?\n\nThey will no longer be able to sign in to the admin dashboard.',
          style: AppTheme.body(size: 13.5, color: AppColors.ink3),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: AppTheme.body(size: 14, color: AppColors.ink4)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove', style: AppTheme.body(size: 14, color: AppColors.clay, weight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AdminProvider>().removeAdmin(email);
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final topPad = MediaQuery.of(context).padding.top;
    final currentEmail = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(22, topPad > 0 ? 12 : 24, 22, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.bone,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back, size: 18, color: AppColors.ink3),
                ),
              ),
              const SizedBox(height: 16),
              const Eyebrow('user management'),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  text: 'Manage ',
                  style: AppTheme.display(size: 26),
                  children: [AppTheme.italicSpan('admins.')],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Grant or revoke admin access. Emails in the superadmin allowlist get full control.',
                style: AppTheme.body(size: 12.5, color: AppColors.ink4),
              ),
              const SizedBox(height: 24),

              // Success / error
              if (admin.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: NoteBox.clay(icon: Icons.error_outline, body: admin.error!),
                ),
              if (admin.successMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: NoteBox.green(icon: Icons.check_circle, body: admin.successMessage!),
                ),

              // Add admin form
              GlassCard(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Eyebrow('add admin'),
                    const SizedBox(height: 4),
                    Text(
                      'Enter an email to grant admin access.',
                      style: AppTheme.body(size: 12.5, color: AppColors.ink4),
                    ),
                    const SizedBox(height: 16),
                    NiuField(
                      label: 'Email address',
                      hint: 'e.g. admin@niu.edu.in',
                      icon: Icons.person_add_outlined,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (val) {
                        setState(() => _emailValid = val.trim().isNotEmpty);
                      },
                      onSubmitted: (_) {
                        if (_emailValid) _addAdmin();
                      },
                    ),
                    const SizedBox(height: 16),
                    admin.isLoading
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
                            label: 'Add admin',
                            variant: NiuButtonVariant.forest,
                            showArrow: true,
                            onTap: _emailValid ? _addAdmin : null,
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Info
              NoteBox.green(
                icon: Icons.mail_outline,
                title: 'Credentials emailed automatically',
                body: 'When you add a new admin, an email with their login URL, email, '
                    'and temporary password is sent to them automatically. '
                    'They can sign in immediately and change their password. '
                    'Emails in SUPERADMIN_EMAILS become super admins; others become '
                    'regular admins with limited access.',
              ),
              const SizedBox(height: 24),

              // Admin list
              const Eyebrow('current admins'),
              const SizedBox(height: 10),

              if (admin.isLoading && admin.admins.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.forest),
                    ),
                  ),
                )
              else if (admin.admins.isEmpty)
                GlassCard(
                  padding: const EdgeInsets.all(22),
                  child: Center(
                    child: Text(
                      'No admins found.',
                      style: AppTheme.body(size: 13.5, color: AppColors.ink4),
                    ),
                  ),
                )
              else
                ...admin.admins.map((a) {
                  final email = a['email'] as String? ?? '';
                  final role = a['role'] as String? ?? 'admin';
                  final isSuper = role == 'superAdmin';
                  final isSelf = email == currentEmail;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSuper
                                  ? AppColors.forestTint
                                  : AppColors.bone,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isSuper ? Icons.shield_outlined : Icons.person_outline,
                              size: 18,
                              color: isSuper ? AppColors.forest : AppColors.ink3,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  email,
                                  style: AppTheme.body(size: 13.5, color: AppColors.ink),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  isSuper ? 'Super Admin' : 'Admin',
                                  style: AppTheme.body(
                                    size: 11,
                                    color: isSuper ? AppColors.forest : AppColors.ink4,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isSelf)
                            IconButton(
                              onPressed: () => _removeAdmin(email),
                              icon: const Icon(Icons.remove_circle_outline,
                                  size: 20, color: AppColors.clay),
                              tooltip: 'Remove admin',
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.forestTint,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'You',
                                style: AppTheme.body(
                                    size: 10, color: AppColors.forest, weight: FontWeight.w600),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
