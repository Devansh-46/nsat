import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../providers/auth_provider.dart' as app;
import '../../widgets/mesh_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/eyebrow.dart';
import '../../widgets/niu_field.dart';
import '../../widgets/niu_button.dart';
import '../../widgets/note_box.dart';
import '../../services/analytics_service.dart';
import '../../widgets/web_split_layout.dart';

/// Step 2 — Two-factor verification: Email OTP + Phone OTP.
///
/// Flow:
/// 1. fetchLeadDetails → get email + mobile from NPF
/// 2. sendOtp Cloud Function → email OTP
/// 3. Student verifies email OTP
/// 4. Firebase Auth phone verification → SMS OTP
/// 5. Student verifies phone OTP → proceed to test
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

enum _VerifyStage { sendingEmail, emailOtp, sendingPhone, phoneOtp, done }

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _emailOtpController = TextEditingController();
  final _phoneOtpController = TextEditingController();

  _VerifyStage _stage = _VerifyStage.sendingEmail;
  bool _busy = false;
  String? _error;
  String? _maskedEmail;
  String? _maskedPhone;
  String? _fullPhone;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startEmailOtp());
  }

  @override
  void dispose() {
    _emailOtpController.dispose();
    _phoneOtpController.dispose();
    super.dispose();
  }

  // ── Step 1: Fetch lead details + send email OTP ──

  Future<void> _startEmailOtp() async {
    final auth = context.read<app.AuthProvider>();
    final student = auth.verifiedStudent;
    if (student == null) return;

    setState(() {
      _stage = _VerifyStage.sendingEmail;
      _busy = true;
      _error = null;
    });

    try {
      final leadOk = await auth.fetchLeadDetails();
      if (!mounted) return;
      if (!leadOk) {
        setState(() {
          _busy = false;
          _error = auth.error ?? 'Could not fetch your details.';
        });
        return;
      }

      final lead = auth.leadDetails!;
      _maskedEmail = _maskEmail(lead.email);
      _fullPhone = lead.mobile;
      _maskedPhone = _maskPhone(lead.mobile);

      // Send email OTP
      final callable = FirebaseFunctions.instanceFor(region: 'asia-south1')
          .httpsCallable('sendOtp');
      await callable.call({
        'application_no': student.applicationNo,
        'email': lead.email,
        'name': lead.name,
      });

      if (!mounted) return;
      AnalyticsService.instance
          .logOtpSent(applicationNo: student.applicationNo);
      setState(() {
        _stage = _VerifyStage.emailOtp;
        _busy = false;
      });
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message ?? 'Failed to send email code.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Failed to send email code. Check your connection.';
      });
    }
  }

  // ── Step 2: Verify email OTP ──

  Future<void> _verifyEmailOtp() async {
    final code = _emailOtpController.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Please enter the 6-digit code.');
      return;
    }

    final auth = context.read<app.AuthProvider>();
    final student = auth.verifiedStudent;
    if (student == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'asia-south1')
          .httpsCallable('verifyOtp');
      await callable.call({
        'application_no': student.applicationNo,
        'code': code,
        'channel': 'email',
      });

      if (!mounted) return;
      // Email verified — now start phone verification
      _startPhoneOtp();
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message ?? 'Email verification failed.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Email verification failed.';
      });
    }
  }

  // ── Step 3: Send phone OTP via Firebase Auth ──

  Future<void> _startPhoneOtp() async {
    if (_fullPhone == null || _fullPhone!.isEmpty) {
      // No phone on file — skip phone verification
      _onFullyVerified();
      return;
    }

    setState(() {
      _stage = _VerifyStage.sendingPhone;
      _busy = true;
      _error = null;
    });

    final auth = context.read<app.AuthProvider>();
    final student = auth.verifiedStudent;
    if (student == null) {
      setState(() {
        _busy = false;
        _error = 'Session expired. Please start over.';
      });
      return;
    }

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'asia-south1')
          .httpsCallable('sendWhatsAppOtp');
      await callable.call({
        'application_no': student.applicationNo,
        'phone': _fullPhone,
        'name': auth.leadDetails?.name,
      });

      if (!mounted) return;
      setState(() {
        _stage = _VerifyStage.phoneOtp;
        _busy = false;
      });
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message ?? 'Failed to send WhatsApp code.';
        _stage = _VerifyStage.phoneOtp; // Let them retry manually
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Failed to send WhatsApp code. Check your connection.';
        _stage = _VerifyStage.phoneOtp;
      });
    }
  }

  // ── Step 4: Verify phone OTP ──

  Future<void> _verifyPhoneOtp() async {
    final code = _phoneOtpController.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Please enter the 6-digit WhatsApp code.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final auth = context.read<app.AuthProvider>();
    final student = auth.verifiedStudent;
    if (student == null) {
      setState(() {
        _busy = false;
        _error = 'Session expired.';
      });
      return;
    }

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'asia-south1')
          .httpsCallable('verifyOtp');
      await callable.call({
        'application_no': student.applicationNo,
        'code': code,
        'channel': 'whatsapp',
      });

      if (!mounted) return;
      _onFullyVerified();
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message ?? 'Invalid WhatsApp code.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Phone verification failed.';
      });
    }
  }

  // ── Both verified → proceed ──

  void _onFullyVerified() async {
    if (!mounted) return;
    final auth = context.read<app.AuthProvider>();
    final student = auth.verifiedStudent;
    if (student != null) {
      AnalyticsService.instance
          .logOtpVerified(applicationNo: student.applicationNo);
    }
    // Sign in anonymously so Firestore rules and Cloud Functions work
    try {
      await fb_auth.FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      debugPrint('Anonymous sign-in failed: $e');
    }
    if (!mounted) return;
    setState(() {
      _stage = _VerifyStage.done;
    });
    Navigator.pushReplacementNamed(context, AppRoutes.testCategory);
  }

  // ── Helpers ──

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return '***@***.***';
    final local = parts[0];
    final domain = parts[1];
    final shown = local.length > 2 ? local.substring(0, 2) : local;
    return '$shown${'*' * (local.length - shown.length)}@$domain';
  }

  String _maskPhone(String phone) {
    if (phone.length < 6) return '****';
    return '${'*' * (phone.length - 4)}${phone.substring(phone.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<app.AuthProvider>();
    final student = auth.verifiedStudent;
    final topPad = MediaQuery.of(context).padding.top;

    final mobileView = Scaffold(
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
                          blurRadius: 18),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    _stage.index >= _VerifyStage.sendingPhone.index
                        ? Icons.phone_android
                        : Icons.mark_email_read_outlined,
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
                  _stage.index >= _VerifyStage.sendingPhone.index
                      ? 'Almost there — verify your phone number.'
                      : 'A 6-digit code has been sent to your email.',
                  style: AppTheme.body(size: 12.5, color: AppColors.ink4),
                ),
                const SizedBox(height: 24),

                // Main card
                GlassCard(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fee verified row
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.forestTint,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.forest.withValues(alpha: 0.15)),
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
                                  Text('Fee verified',
                                      style: AppTheme.body(
                                          size: 12.5,
                                          color: AppColors.forest,
                                          weight: FontWeight.w600)),
                                  const SizedBox(height: 1),
                                  Text(
                                      'NIU ID  ${student?.applicationNo ?? "-"}',
                                      style: AppTheme.mono(
                                          size: 11.5, color: AppColors.ink3)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Progress indicator ──
                      Row(
                        children: [
                          _StepDot(
                            label: 'Email',
                            done:
                                _stage.index >= _VerifyStage.sendingPhone.index,
                            active:
                                _stage.index < _VerifyStage.sendingPhone.index,
                          ),
                          Expanded(
                              child:
                                  Container(height: 1, color: AppColors.line2)),
                          _StepDot(
                            label: 'Phone',
                            done: _stage == _VerifyStage.done,
                            active: _stage.index >=
                                    _VerifyStage.sendingPhone.index &&
                                _stage != _VerifyStage.done,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Stage-specific content ──
                      if (_stage == _VerifyStage.sendingEmail) ...[
                        const SizedBox(height: 20),
                        const Center(
                            child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.forest))),
                        const SizedBox(height: 8),
                        Center(
                            child: Text('Sending verification code…',
                                style: AppTheme.body(
                                    size: 12.5, color: AppColors.ink4))),
                      ] else if (_stage == _VerifyStage.emailOtp) ...[
                        if (_maskedEmail != null) ...[
                          const Eyebrow('verification email sent to'),
                          const SizedBox(height: 4),
                          Text(_maskedEmail!,
                              style: AppTheme.mono(
                                  size: 14, color: AppColors.ink)),
                          const SizedBox(height: 16),
                        ],
                        NiuField(
                          label: 'Email verification code',
                          hint: '6-digit code',
                          icon: Icons.email_outlined,
                          controller: _emailOtpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          errorText: _error,
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: _startEmailOtp,
                          child: Text('Resend code',
                              style: AppTheme.body(
                                      size: 12,
                                      color: AppColors.forest,
                                      weight: FontWeight.w600)
                                  .copyWith(
                                      decoration: TextDecoration.underline)),
                        ),
                        const SizedBox(height: 20),
                        _busy
                            ? const SizedBox(
                                height: 48,
                                child: Center(
                                    child: SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: AppColors.forest))))
                            : NiuButton(
                                label: 'Verify email',
                                showArrow: true,
                                onTap: _verifyEmailOtp),
                      ] else if (_stage == _VerifyStage.sendingPhone) ...[
                        const NoteBox.green(
                            icon: Icons.check_circle,
                            body: 'Email verified successfully!'),
                        const SizedBox(height: 16),
                        const Center(
                            child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.forest))),
                        const SizedBox(height: 8),
                        Center(
                            child: Text('Sending WhatsApp code…',
                                style: AppTheme.body(
                                    size: 12.5, color: AppColors.ink4))),
                      ] else if (_stage == _VerifyStage.phoneOtp) ...[
                        const NoteBox.green(
                            icon: Icons.check_circle,
                            body: 'Email verified successfully!'),
                        const SizedBox(height: 16),
                        if (_maskedPhone != null) ...[
                          const Eyebrow('whatsapp sent to'),
                          const SizedBox(height: 4),
                          Text(_maskedPhone!,
                              style: AppTheme.mono(
                                  size: 14, color: AppColors.ink)),
                          const SizedBox(height: 16),
                        ],
                        NiuField(
                          label: 'WhatsApp verification code',
                          hint: '6-digit code',
                          icon: Icons.chat_bubble_outline,
                          controller: _phoneOtpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          errorText: _error,
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: _startPhoneOtp,
                          child: Text('Resend WhatsApp',
                              style: AppTheme.body(
                                      size: 12,
                                      color: AppColors.forest,
                                      weight: FontWeight.w600)
                                  .copyWith(
                                      decoration: TextDecoration.underline)),
                        ),
                        const SizedBox(height: 20),
                        _busy
                            ? const SizedBox(
                                height: 48,
                                child: Center(
                                    child: SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: AppColors.forest))))
                            : NiuButton(
                                label: 'Verify & continue',
                                showArrow: true,
                                variant: NiuButtonVariant.forest,
                                onTap: _verifyPhoneOtp),
                      ],

                      // ── Error fallback (for sendingEmail failures) ──
                      if (_error != null &&
                          (_stage == _VerifyStage.sendingEmail)) ...[
                        const SizedBox(height: 16),
                        NoteBox.clay(icon: Icons.error_outline, body: _error!),
                        const SizedBox(height: 16),
                        NiuButton(
                            label: 'Retry',
                            variant: NiuButtonVariant.outline,
                            onTap: _startEmailOtp),
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

    final leftPanel = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Image.asset('assets/niu_crest.png', width: 24, height: 24),
            const SizedBox(width: 12),
            Text('NSAT',
                style: AppTheme.mono(
                    color: AppColors.ivory.withValues(alpha: 0.5))),
            const SizedBox(width: 8),
            Text('/',
                style: AppTheme.mono(
                    color: AppColors.ivory.withValues(alpha: 0.2))),
            const SizedBox(width: 8),
            Text('NOIDA INTERNATIONAL UNIVERSITY',
                style: AppTheme.eyebrow(
                    color: AppColors.ivory.withValues(alpha: 0.5))),
          ],
        ),
        const SizedBox(height: 16),
        Text('Student / Identity verification',
            style: AppTheme.body(size: 14, color: AppColors.ivory)),
        const SizedBox(height: 64),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text('STEP 02 OF 04 — SECURITY',
              style: AppTheme.eyebrow(color: AppColors.ivory)),
        ),
        const SizedBox(height: 24),
        Text.rich(
          TextSpan(
            style: AppTheme.display(size: 52, color: AppColors.ivory),
            children: [
              const TextSpan(text: 'Verify your\n'),
              AppTheme.italicSpan('identity.', color: AppColors.ivory),
            ],
          ),
        ),
        const Spacer(),
        // ── Step indicator ──
        Row(
          children: List.generate(4, (i) {
            final active = i == 1;
            return Container(
              margin: const EdgeInsets.only(right: 6),
              width: active ? 22 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: active
                    ? AppColors.ivory
                    : AppColors.ivory.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Support',
                    style: AppTheme.eyebrow(
                        color: AppColors.ivory.withValues(alpha: 0.5))),
                const SizedBox(height: 4),
                Text('nsat@niu.edu.in',
                    style: AppTheme.mono(size: 12, color: AppColors.ivory)),
              ],
            ),
          ],
        ),
      ],
    );

    final rightPanel = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('VERIFICATION'),
        const SizedBox(height: 16),
        GlassCard(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fee verified row
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.forestTint,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.forest.withValues(alpha: 0.15)),
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
                          Text('Fee verified',
                              style: AppTheme.body(
                                  size: 12.5,
                                  color: AppColors.forest,
                                  weight: FontWeight.w600)),
                          const SizedBox(height: 1),
                          Text('NIU ID  ${student?.applicationNo ?? "-"}',
                              style: AppTheme.mono(
                                  size: 11.5, color: AppColors.ink3)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Progress indicator ──
              Row(
                children: [
                  _StepDot(
                    label: 'Email',
                    done: _stage.index >= _VerifyStage.sendingPhone.index,
                    active: _stage.index < _VerifyStage.sendingPhone.index,
                  ),
                  Expanded(child: Container(height: 1, color: AppColors.line2)),
                  _StepDot(
                    label: 'Phone',
                    done: _stage == _VerifyStage.done,
                    active: _stage.index >= _VerifyStage.sendingPhone.index &&
                        _stage != _VerifyStage.done,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Stage-specific content ──
              if (_stage == _VerifyStage.sendingEmail) ...[
                const SizedBox(height: 20),
                const Center(
                    child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: AppColors.forest))),
                const SizedBox(height: 8),
                Center(
                    child: Text('Sending verification code…',
                        style:
                            AppTheme.body(size: 12.5, color: AppColors.ink4))),
              ] else if (_stage == _VerifyStage.emailOtp) ...[
                if (_maskedEmail != null) ...[
                  const Eyebrow('verification email sent to'),
                  const SizedBox(height: 4),
                  Text(_maskedEmail!,
                      style: AppTheme.mono(size: 14, color: AppColors.ink)),
                  const SizedBox(height: 16),
                ],
                NiuField(
                  label: 'Email verification code',
                  hint: '6-digit code',
                  icon: Icons.email_outlined,
                  controller: _emailOtpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  errorText: _error,
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _startEmailOtp,
                  child: Text('Resend code',
                      style: AppTheme.body(
                              size: 12,
                              color: AppColors.forest,
                              weight: FontWeight.w600)
                          .copyWith(decoration: TextDecoration.underline)),
                ),
                const SizedBox(height: 20),
                _busy
                    ? const SizedBox(
                        height: 48,
                        child: Center(
                            child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.forest))))
                    : NiuButton(
                        label: 'Verify email',
                        showArrow: true,
                        onTap: _verifyEmailOtp),
              ] else if (_stage == _VerifyStage.sendingPhone) ...[
                const NoteBox.green(
                    icon: Icons.check_circle,
                    body: 'Email verified successfully!'),
                const SizedBox(height: 16),
                const Center(
                    child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: AppColors.forest))),
                const SizedBox(height: 8),
                Center(
                    child: Text('Sending WhatsApp code…',
                        style:
                            AppTheme.body(size: 12.5, color: AppColors.ink4))),
              ] else if (_stage == _VerifyStage.phoneOtp) ...[
                const NoteBox.green(
                    icon: Icons.check_circle,
                    body: 'Email verified successfully!'),
                const SizedBox(height: 16),
                if (_maskedPhone != null) ...[
                  const Eyebrow('whatsapp sent to'),
                  const SizedBox(height: 4),
                  Text(_maskedPhone!,
                      style: AppTheme.mono(size: 14, color: AppColors.ink)),
                  const SizedBox(height: 16),
                ],
                NiuField(
                  label: 'WhatsApp verification code',
                  hint: '6-digit code',
                  icon: Icons.chat_bubble_outline,
                  controller: _phoneOtpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  errorText: _error,
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _startPhoneOtp,
                  child: Text('Resend WhatsApp',
                      style: AppTheme.body(
                              size: 12,
                              color: AppColors.forest,
                              weight: FontWeight.w600)
                          .copyWith(decoration: TextDecoration.underline)),
                ),
                const SizedBox(height: 20),
                _busy
                    ? const SizedBox(
                        height: 48,
                        child: Center(
                            child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.forest))))
                    : NiuButton(
                        label: 'Verify & continue',
                        showArrow: true,
                        variant: NiuButtonVariant.forest,
                        onTap: _verifyPhoneOtp),
              ],

              // ── Error fallback (for sendingEmail failures) ──
              if (_error != null && (_stage == _VerifyStage.sendingEmail)) ...[
                const SizedBox(height: 16),
                NoteBox.clay(icon: Icons.error_outline, body: _error!),
                const SizedBox(height: 16),
                NiuButton(
                    label: 'Retry',
                    variant: NiuButtonVariant.outline,
                    onTap: _startEmailOtp),
              ],
            ],
          ),
        ),
      ],
    );

    return WebSplitLayout(
      leftChild: leftPanel,
      rightChild: rightPanel,
      mobileChild: mobileView,
    );
  }
}

// ── Mini step dot for email/phone progress ──

class _StepDot extends StatelessWidget {
  final String label;
  final bool done;
  final bool active;
  const _StepDot(
      {required this.label, required this.done, required this.active});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done
                ? AppColors.forest
                : active
                    ? AppColors.forestTint
                    : AppColors.bone,
            border: Border.all(
                color: done || active ? AppColors.forest : AppColors.line,
                width: 1.5),
          ),
          child: done
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : active
                  ? const Icon(Icons.circle, size: 8, color: AppColors.forest)
                  : null,
        ),
        const SizedBox(height: 4),
        Text(label,
            style: AppTheme.body(
                size: 10,
                color: done || active ? AppColors.forest : AppColors.ink4,
                weight: done || active ? FontWeight.w600 : FontWeight.w400)),
      ],
    );
  }
}

// ── Step indicator ──

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
                      weight: FontWeight.w600)),
              const TextSpan(text: '  ·  '),
              for (int i = 0; i < _labels.length; i++) ...[
                if (i > 0) const TextSpan(text: '  ›  '),
                TextSpan(
                    text: _labels[i],
                    style: AppTheme.body(
                        size: 11.5,
                        color: i == current ? AppColors.forest : AppColors.ink4,
                        weight:
                            i == current ? FontWeight.w600 : FontWeight.w400)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
