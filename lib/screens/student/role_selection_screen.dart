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

/// App entry point — choose Student or Admin.
/// Verdant Daylight reskin.
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
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
                    'v1.0 — NIU IT Team',
                    style: AppTheme.body(size: 10.5, color: AppColors.ink5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}