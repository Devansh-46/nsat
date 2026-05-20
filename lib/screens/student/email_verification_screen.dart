import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/mesh_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/eyebrow.dart';
import '../../widgets/niu_field.dart';
import '../../widgets/niu_button.dart';
import '../../widgets/note_box.dart';

/// Step 2 — Email OTP verification.
///
/// Flow: shows masked email → sendOtp Cloud Function → student enters
/// 6-digit code → verifyOtp Cloud Function → fetchLeadDetails → test.
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _sending = false;
  bool _verifying = false;
  String? _error;
  String? _maskedEmail;

  @override
  void initState() {
    super.initState();
    // Auto-send OTP on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendOtp());
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final auth = context.read<AuthProvider>();
    final student = auth.verifiedStudent;
    if (student == null) return;

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      // First fetch lead details to get the email
      final leadOk = await auth.fetchLeadDetails();
      if (!mounted) return;
      if (!leadOk) {
        setState(() {
          _sending = false;
          _error = auth.error ?? 'Could not fetch your details.';
        });
        return;
      }

      final lead = auth.leadDetails!;
      _maskedEmail = _maskEmail(lead.email);

      // Call sendOtp Cloud Function
      final callable = FirebaseFunctions.instanceFor(region: 'asia-south1')
          .httpsCallable('sendOtp');
      await callable.call({
        'application_no': student.applicationNo,
        'email': lead.email,
        'name': lead.name,
      });

      if (!mounted) return;
      setState(() {
        _sending = false;
        _otpSent = true;
      });
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e.message ?? 'Failed to send verification code.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = 'Failed to send verification code. Check your connection.';
      });
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Please enter the 6-digit code.');
      return;
    }

    final auth = context.read<AuthProvider>();
    final student = auth.verifiedStudent;
    if (student == null) return;

    setState(() {
      _verifying = true;
      _error = null;
    });

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'asia-south1')
          .httpsCallable('verifyOtp');
      await callable.call({
        'application_no': student.applicationNo,
        'code': code,
      });

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.testCategory);
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = e.message ?? 'Verification failed.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = 'Verification failed. Check your connection.';
      });
    }
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return '***@***.***';
    final local = parts[0];
    final domain = parts[1];
    final shown = local.length > 2 ? local.substring(0, 2) : local;
    return '$shown${'*' * (local.length - shown.length)}@$domain';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final student = auth.verifiedStudent;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: MeshBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(22, topPad > 0 ? 12 : 28, 22, 32),
            child: Column(
              children: [
                // Header icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: AppColors.glassBgStrong,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.glassBorder),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x120F2A1F),
                        offset: Offset(0, 6),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    size: 28,
                    color: AppColors.forest,
                  ),
                ),
                const SizedBox(height: 14),
                Text.rich(
                  TextSpan(
                    text: 'Verify your ',
                    style: AppTheme.displaySm(size: 22),
                    children: [AppTheme.italicSpan('identity.')],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'A 6-digit code has been sent to your email.',
                  style: AppTheme.body(size: 12.5, color: AppColors.ink4),
                ),
                const SizedBox(height: 24),

                // Main card
                GlassCard(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fee-verified row
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.forestTint,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.forest.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                size: 18, color: AppColors.forest),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Fee verified',
                                    style: AppTheme.body(
                                      size: 12.5,
                                      color: AppColors.forest,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    'NIU ID  ${student?.applicationNo ?? "-"}',
                                    style: AppTheme.mono(
                                      size: 11.5,
                                      color: AppColors.ink3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Email info
                      if (_maskedEmail != null) ...[
                        const Eyebrow('verification email sent to'),
                        const SizedBox(height: 4),
                        Text(
                          _maskedEmail!,
                          style: AppTheme.mono(
                              size: 14, color: AppColors.ink),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (_sending) ...[
                        const SizedBox(height: 20),
                        const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.forest,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Sending verification code…',
                            style: AppTheme.body(
                                size: 12.5, color: AppColors.ink4),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ] else if (_otpSent) ...[
                        // OTP input
                        NiuField(
                          label: 'Verification code',
                          hint: '6-digit code',
                          icon: Icons.lock_outline,
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          errorText: _error,
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: _sendOtp,
                          child: Text(
                            'Resend code',
                            style: AppTheme.body(
                              size: 12,
                              color: AppColors.forest,
                              weight: FontWeight.w600,
                            ).copyWith(
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (_verifying)
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
                          NiuButton(
                            label: 'Verify & continue',
                            showArrow: true,
                            onTap: _verifyOtp,
                          ),
                      ] else if (_error != null) ...[
                        NoteBox.clay(
                          icon: Icons.error_outline,
                          body: _error!,
                        ),
                        const SizedBox(height: 16),
                        NiuButton(
                          label: 'Retry',
                          variant: NiuButtonVariant.outline,
                          onTap: _sendOtp,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 28),
                const _StepIndicator(current: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int current;
  const _StepIndicator({this.current = 0});
  static const _labels = ['ID', 'Email', 'Verify', 'Test'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final active = i == current;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 22 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: active ? AppColors.forest : AppColors.bone,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        Text.rich(
          TextSpan(
            style: AppTheme.body(size: 11.5, color: AppColors.ink4),
            children: [
              TextSpan(
                text: 'Step ${current + 1} of 4',
                style: AppTheme.body(
                  size: 11.5,
                  color: AppColors.ink3,
                  weight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: '  ·  '),
              for (int i = 0; i < _labels.length; i++) ...[
                if (i > 0) const TextSpan(text: '  ›  '),
                TextSpan(
                  text: _labels[i],
                  style: AppTheme.body(
                    size: 11.5,
                    color: i == current ? AppColors.forest : AppColors.ink4,
                    weight: i == current ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}