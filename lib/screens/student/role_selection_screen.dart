import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../widgets/mesh_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/eyebrow.dart';
import '../../widgets/niu_button.dart';
import '../../widgets/note_box.dart';
import '../../services/remote_config_service.dart';
import '../../widgets/web_split_layout.dart';

/// App entry point — choose Student or Admin.
/// Verdant Daylight reskin.
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    final mobileView = Scaffold(
      backgroundColor: AppColors.bgBase,
      body: MeshBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(22, topPad > 0 ? 12 : 36, 22, 32),
              child: Column(
                children: [
                  // ── Crest ──
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      gradient: AppColors.glassBgStrong,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.glassBorder),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x120F2A1F),
                          offset: Offset(0, 8),
                          blurRadius: 22,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Image.asset(
                        'assets/niu_crest.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Noida International University',
                    style: AppTheme.body(
                      size: 13,
                      color: AppColors.ink3,
                      weight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('NSAT', style: AppTheme.display(size: 38)),
                  const SizedBox(height: 2),
                  Text(
                    'Student Aptitude Test',
                    style: AppTheme.body(size: 12.5, color: AppColors.ink4),
                  ),
                  const SizedBox(height: 28),

                  // ── Session banner ──
                  GlassCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    radius: 14,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.school_outlined,
                            size: 16, color: AppColors.forest),
                        const SizedBox(width: 10),
                        Text(
                          '2026 — 27 Admissions',
                          style: AppTheme.body(
                            size: 13,
                            color: AppColors.ink,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Maintenance banner (if active) ──
                  if (RemoteConfigService.instance.isMaintenanceMode)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: NoteBox.gold(
                        icon: Icons.construction_rounded,
                        title: 'Maintenance',
                        body: RemoteConfigService.instance.maintenanceMessage,
                      ),
                    ),

                  // ── Role card ──
                  GlassCard(
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                    child: Column(
                      children: [
                        const Eyebrow('select role'),
                        const SizedBox(height: 12),
                        NiuButton(
                          label: 'Student login',
                          variant: NiuButtonVariant.forest,
                          showArrow: true,
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.studentLogin),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Login with your NIU ID',
                          style:
                              AppTheme.body(size: 11.5, color: AppColors.ink4),
                        ),
                        const SizedBox(height: 18),
                        NiuButton(
                          label: 'Admin login',
                          variant: NiuButtonVariant.outline,
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.adminLogin),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text(
                    '© 2026 Noida International University. All rights reserved.',
                    style: AppTheme.body(size: 10.5, color: AppColors.ink5),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
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
            Image.asset('assets/niu_crest.png', height: 48),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NOIDA INTERNATIONAL UNIVERSITY',
                    style: AppTheme.eyebrow(
                        color: AppColors.ivory.withValues(alpha: 0.7))),
                Text('NSAT',
                    style:
                        AppTheme.displaySm(size: 18, color: AppColors.ivory)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 64),
        Text.rich(
          TextSpan(
            style: AppTheme.display(size: 56, color: AppColors.ivory),
            children: [
              const TextSpan(text: 'Student Aptitude\n'),
              AppTheme.italicSpan('Test.', color: AppColors.ivory),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.school_outlined,
                  size: 16, color: AppColors.ivory),
              const SizedBox(width: 10),
              Text(
                '2026 — 27 Admissions',
                style: AppTheme.body(
                    size: 13, color: AppColors.ivory, weight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const Spacer(),
      ],
    );

    final rightPanel = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('welcome — please choose your role'),
        const SizedBox(height: 8),
        Text('Sign in to begin or\nadminister the test.',
            style: AppTheme.displaySm()),
        const SizedBox(height: 32),
        // Maintenance banner (if active)
        if (RemoteConfigService.instance.isMaintenanceMode)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: NoteBox.gold(
              icon: Icons.construction_rounded,
              title: 'Maintenance',
              body: RemoteConfigService.instance.maintenanceMessage,
            ),
          ),
        GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _ActionRow(
                icon: Icons.person_outline,
                title: 'Student Login',
                subtitle: 'Take your aptitude test',
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.studentLogin),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Container(height: 1, color: AppColors.line2),
              ),
              _ActionRow(
                icon: Icons.admin_panel_settings_outlined,
                title: 'Admin Login',
                subtitle: 'Manage tests & results',
                onTap: () => Navigator.pushNamed(context, AppRoutes.adminLogin),
              ),
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

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppTheme.mono(size: 20, color: AppColors.ivory)),
        const SizedBox(height: 2),
        Text(label,
            style: AppTheme.body(
                size: 11.5, color: AppColors.ivory.withValues(alpha: 0.7))),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.forestTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.forest),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTheme.body(
                        size: 14.5,
                        color: AppColors.ink,
                        weight: FontWeight.w600)),
                Text(subtitle,
                    style: AppTheme.body(size: 12, color: AppColors.ink4)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward, size: 20, color: AppColors.ink4),
        ],
      ),
    );
  }
}
