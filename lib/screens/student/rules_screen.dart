import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/mesh_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/eyebrow.dart';
import '../../widgets/niu_button.dart';
import '../../widgets/web_split_layout.dart';

/// Rules & Regulations screen — displayed before the student starts a test.
/// The student must scroll through all rules and check the acceptance box
/// before the "Proceed to test" button becomes active.
class RulesScreen extends StatefulWidget {
  const RulesScreen({super.key});

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen>
    with SingleTickerProviderStateMixin {
  bool _accepted = false;
  bool _showScrollHint = true;
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _bounceController;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_showScrollHint && _scrollController.offset > 100) {
      setState(() => _showScrollHint = false);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _proceed() {
    if (!_accepted) return;
    // Pop with `true` to signal the caller (TestCategoryScreen) to start
    Navigator.pop(context, true);
  }

  // ─── Rule data ──────────────────────────────────────────────────────

  // (Login steps removed — students are already logged in at this point)

  static const _systemRequirements = [
    'A laptop or desktop is recommended. If using a phone, '
        'use an updated Chrome or Safari browser.',
    'A stable, uninterrupted internet connection throughout the test.',
    'A charged device (keep your charger connected if possible).',
    'Close all other tabs and applications before you begin.',
  ];

  static const _rules = [
    'One attempt only. Once you submit, the test cannot be '
        'reopened or retaken. The test will also auto-submit '
        'when your login window closes.',
    'Log in early within your window. Do not wait until the '
        'last moment — you need enough time to complete the test '
        'before the window closes.',
    'Do not refresh, close, or navigate away from the test screen, '
        'and do not use the browser back button — this may disrupt '
        'your session.',
    'The test contains multiple-choice questions and descriptive '
        '(short-answer) questions. Answer all sections to the best '
        'of your ability.',
    'This is an individual assessment. Seeking or providing help, '
        'using unfair means, or sharing exam content is strictly '
        'prohibited and may result in cancellation of your candidature.',
    'Do not share your Application Number or OTP with anyone.',
    'Keep your registered email accessible during login, as your '
        'OTP is sent there.',
    'In case of a technical issue during the test, contact your '
        'counsellor immediately — do not start a fresh attempt '
        'without guidance.',
  ];

  static const _platformRules = [
    'Fullscreen mode is mandatory. The test will launch in fullscreen '
        'mode. Do not exit fullscreen during the exam — this may be '
        'treated as suspicious activity.',
    'Tab / app switching is monitored. If you switch to another tab, '
        'app, or window during the test, you will receive a warning on '
        'your first violation. On the second violation, your test will '
        'be automatically submitted with whatever answers you have '
        'completed so far.',
    'Auto-submitted tests due to tab-switching or suspicious activity '
        'will NOT be eligible for a re-attempt. The submitted result '
        'will be considered final.',
    'Timer is final. The test has a fixed duration. Once the timer '
        'runs out, the test will be auto-submitted regardless of how '
        'many questions remain unanswered.',
    'Per-question timers (if applicable). Some questions may have '
        'individual time limits. Once the time for a question expires, '
        'it will be locked and you cannot go back to answer it.',
    'Ensure your device does not go to sleep or activate a screen '
        'lock during the test — this may trigger the tab-switch violation.',
    'Do not use screen recording, screenshot tools, or any '
        'third-party overlay apps during the exam.',
    'Negative marking applies (if configured for your test). '
        'Incorrect answers on MCQs will result in a deduction of marks. '
        'Unanswered questions carry no penalty.',
    'Answer all sections carefully. MCQ answers can be changed or '
        'cleared before submission. Descriptive (short-answer) questions '
        'must meet the specified word count range.',
  ];

  // ─── Builders ───────────────────────────────────────────────────────

  Widget _buildScrollHint() {
    return AnimatedOpacity(
      opacity: _showScrollHint ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      child: AnimatedBuilder(
        animation: _bounceController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _bounceController.value * 6),
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.forestTint,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.forest.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.keyboard_double_arrow_down_rounded,
                size: 18,
                color: AppColors.forest,
              ),
              const SizedBox(width: 8),
              Text(
                'Scroll down to accept rules',
                style: AppTheme.body(
                  size: 12.5,
                  color: AppColors.forest,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRulesContent({bool isWeb = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Scroll hint ──
        Center(child: _buildScrollHint()),
        const SizedBox(height: 16),

        // ── Exam Rules ──
        _SectionHeader(
          icon: Icons.gavel_rounded,
          title: 'Rules & Regulations',
          subtitle: 'Non-compliance may lead to disqualification',
        ),
        const SizedBox(height: 10),
        GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              for (int i = 0; i < _rules.length; i++) ...[
                if (i > 0) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Divider(
                      height: 1,
                      color: AppColors.line2,
                    ),
                  ),
                ],
                _NumberedRule(
                  index: i + 1,
                  text: _rules[i],
                  isWarning: i == 0 || i == 4,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),

        // ── Platform-Specific Rules ──
        _SectionHeader(
          icon: Icons.security_rounded,
          title: 'Platform & Proctoring Rules',
          subtitle: 'Enforced automatically by the system',
        ),
        const SizedBox(height: 10),

        // Auto-submit warning callout
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.clayTint2, AppColors.clayTint],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x4DB0432F)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 16, color: AppColors.clay),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'If your test is auto-submitted due to tab-switching '
                  'or any suspicious activity, a re-attempt will NOT be '
                  'provided. The result will be considered final.',
                  style: AppTheme.body(
                    size: 12.5,
                    color: AppColors.clay,
                    weight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              for (int i = 0; i < _platformRules.length; i++) ...[
                if (i > 0) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Divider(
                      height: 1,
                      color: AppColors.line2,
                    ),
                  ),
                ],
                _NumberedRule(
                  index: i + 1,
                  text: _platformRules[i],
                  isWarning: i == 0 || i == 1 || i == 2,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),

        // ── System & Connectivity Requirements (moved to end) ──
        _SectionHeader(
          icon: Icons.devices_rounded,
          title: 'System & Connectivity Requirements',
        ),
        const SizedBox(height: 10),
        GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              for (int i = 0; i < _systemRequirements.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                _BulletRule(text: _systemRequirements[i]),
              ],
            ],
          ),
        ),
        const SizedBox(height: 28),

        // ── Accept checkbox ──
        GestureDetector(
          onTap: () => setState(() => _accepted = !_accepted),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 16, 18, 16),
            decoration: BoxDecoration(
              gradient: _accepted
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.forestTint2, AppColors.forestTint],
                    )
                  : AppColors.glassBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _accepted
                    ? AppColors.forest.withValues(alpha: 0.4)
                    : AppColors.glassBorder,
                width: _accepted ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _accepted ? AppColors.forest : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: _accepted ? AppColors.forest : AppColors.ink5,
                      width: 2,
                    ),
                  ),
                  child: _accepted
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'I have read and understood all the rules & regulations '
                    'above. I agree to abide by them during the test.',
                    style: AppTheme.body(
                      size: 13,
                      color: _accepted ? AppColors.forest : AppColors.ink3,
                      weight:
                          _accepted ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // ── Proceed button ──
        NiuButton(
          label: 'Proceed to test',
          variant: NiuButtonVariant.forest,
          showArrow: true,
          onTap: _accepted ? _proceed : null,
        ),

        if (!isWeb) ...[
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Scroll up to review all rules before proceeding',
              style: AppTheme.body(size: 11.5, color: AppColors.ink4),
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    final mobileView = Scaffold(
      backgroundColor: AppColors.bgBase,
      body: MeshBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── Fixed header ──
              Padding(
                padding: EdgeInsets.fromLTRB(
                    22, topPad > 0 ? 8 : 16, 22, 0),
                child: Row(
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
                        child: const Icon(Icons.chevron_left,
                            size: 20, color: AppColors.ink3),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Eyebrow('before you begin'),
                          const SizedBox(height: 2),
                          Text(
                            'Rules & Regulations',
                            style: AppTheme.displaySm(size: 18),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Scrollable rules ──
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 32),
                  child: _buildRulesContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // ── Web layout ──

    final leftPanel = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Image.asset('assets/niu_crest.png', width: 24, height: 24),
            const SizedBox(width: 12),
            Text(
              'NSAT',
              style: AppTheme.mono(
                color: AppColors.ivory.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '/',
              style: AppTheme.mono(
                color: AppColors.ivory.withValues(alpha: 0.2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'NOIDA INTERNATIONAL UNIVERSITY',
              style: AppTheme.eyebrow(
                color: AppColors.ivory.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Student / Rules & Regulations',
          style: AppTheme.body(size: 14, color: AppColors.ivory),
        ),
        const SizedBox(height: 64),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'IMPORTANT — READ CAREFULLY',
            style: AppTheme.eyebrow(color: AppColors.ivory),
          ),
        ),
        const SizedBox(height: 24),
        Text.rich(
          TextSpan(
            style: AppTheme.display(size: 46, color: AppColors.ivory),
            children: [
              const TextSpan(text: 'Rules &\n'),
              AppTheme.italicSpan('Regulations.', color: AppColors.ivory),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Please read all the rules carefully before\n'
          'proceeding to your test. Non-compliance\n'
          'may lead to disqualification.',
          style: AppTheme.body(
            size: 14,
            color: AppColors.ivory.withValues(alpha: 0.6),
          ),
        ),
        const Spacer(),
        // ── Step indicator ──
        Row(
          children: List.generate(4, (i) {
            // This is between step 3 (test info) and step 4 (live test)
            // We highlight the 3rd dot to show we're still in step 3 flow
            final active = i == 2;
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
            Column(crossAxisAlignment: CrossAxisAlignment.start),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Support',
                  style: AppTheme.eyebrow(
                    color: AppColors.ivory.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'nsat@niu.edu.in',
                  style: AppTheme.mono(size: 12, color: AppColors.ivory),
                ),
              ],
            ),
          ],
        ),
      ],
    );

    final rightPanel = SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 60),
      child: _buildRulesContent(isWeb: true),
    );

    return WebSplitLayout(
      leftChild: leftPanel,
      rightChild: rightPanel,
      mobileChild: mobileView,
    );
  }
}

// ─── Section header ─────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.forestTint,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: AppColors.forest),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.displaySm(size: 15),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 1),
                Text(
                  subtitle!,
                  style: AppTheme.body(size: 11.5, color: AppColors.clay),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Numbered rule item ─────────────────────────────────────────────

class _NumberedRule extends StatelessWidget {
  final int index;
  final String text;
  final bool isWarning;

  const _NumberedRule({
    required this.index,
    required this.text,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.only(top: 1),
          decoration: BoxDecoration(
            color: isWarning ? AppColors.clayTint : AppColors.bone,
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.center,
          child: Text(
            '$index',
            style: AppTheme.mono(
              size: 11,
              color: isWarning ? AppColors.clay : AppColors.ink4,
              weight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTheme.body(
              size: 13,
              color: isWarning ? AppColors.ink2 : AppColors.ink3,
              weight: isWarning ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Bullet rule item ───────────────────────────────────────────────

class _BulletRule extends StatelessWidget {
  final String text;

  const _BulletRule({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 7, right: 10, left: 9),
          decoration: BoxDecoration(
            color: AppColors.forest,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: AppTheme.body(size: 13, color: AppColors.ink3),
          ),
        ),
      ],
    );
  }
}
