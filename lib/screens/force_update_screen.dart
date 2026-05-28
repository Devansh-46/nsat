import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/remote_config_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/mesh_background.dart';
import '../widgets/niu_button.dart';

/// Full-screen blocking overlay shown when the app's versionCode
/// is below [RemoteConfigService.minVersionCode].
///
/// No back button, no dismiss — the only action is "Update Now"
/// which opens the Play Store / App Store listing.
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key});

  Future<void> _openStore() async {
    final url = RemoteConfigService.instance.playStoreUrl;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Block back button
      child: Scaffold(
        body: MeshBackground(
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: GlassCard(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.forestTint,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.system_update_rounded,
                          size: 32,
                          color: AppColors.forest,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Update Required',
                        style: AppTheme.display(size: 24),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        RemoteConfigService.instance.forceUpdateMessage,
                        style: AppTheme.body(
                          size: 14,
                          color: AppColors.ink3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      NiuButton(
                        label: 'Update Now',
                        onTap: _openStore,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
