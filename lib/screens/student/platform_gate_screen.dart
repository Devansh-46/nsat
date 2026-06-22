import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';


import '../../routes/app_routes.dart';
import '../../widgets/mesh_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/eyebrow.dart';
import '../../services/remote_config_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class PlatformGateScreen extends StatefulWidget {
  const PlatformGateScreen({super.key});
  @override
  State<PlatformGateScreen> createState() => _PlatformGateScreenState();
}

class _PlatformGateScreenState extends State<PlatformGateScreen> {
  @override
  void initState() {
    super.initState();
    // The gate is meaningless inside the native app — skip straight through.
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
        }
      });
    }
  }

  void _continueWeb() =>
      Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, webOnlyWindowName: '_blank');
  }

  Future<void> _chooseAndroid() async {
    final rc = RemoteConfigService.instance;
    if (rc.isAndroidAppLive) {
      await _launch(rc.playStoreUrl);
    } else {
      _continueWeb();
    }
  }

  Future<void> _chooseIos() async {
    final rc = RemoteConfigService.instance;
    if (rc.isIosAppLive) {
      await _launch(rc.appStoreUrl);
    } else {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(const SnackBar(
        content: Text('The iOS app is launching soon — continuing in your browser.'),
      ));
      _continueWeb();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Native: brief loader while the post-frame redirect fires.
    if (!kIsWeb) {
      return const Scaffold(
        body: MeshBackground(child: Center(child: CircularProgressIndicator())),
      );
    }

    return Scaffold(
      body: MeshBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Eyebrow('NSAT'),
                      const SizedBox(height: 12),
                      Text('How are you taking the test?',
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text(
                        'For the best and most secure exam experience on a phone or tablet, '
                        'use the NSAT app. On a laptop or desktop, continue in your browser.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 32),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: [
                          _PlatformBox(
                            icon: Icons.android,
                            label: 'Android phone / tablet',
                            onTap: _chooseAndroid,
                            color: AppColors.forest,
                          ),
                          _PlatformBox(
                            icon: Icons.apple,
                            label: 'iPhone / iPad',
                            onTap: _chooseIos,
                            color: AppColors.ink,
                          ),
                          _PlatformBox(
                            icon: Icons.laptop_mac,
                            label: 'Laptop / Desktop\ncontinue in browser',
                            onTap: _continueWeb,
                            color: AppColors.forest,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Always-available escape so no one is ever stranded.
                      TextButton(
                        onPressed: _continueWeb,
                        child: const Text('Continue in browser anyway'),
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

class _PlatformBox extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _PlatformBox({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  State<_PlatformBox> createState() => _PlatformBoxState();
}

class _PlatformBoxState extends State<_PlatformBox> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 144,
          height: 168,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: _hovered ? Colors.white.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered ? widget.color : AppColors.line2,
              width: 1,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 42, color: widget.color),
              const SizedBox(height: 16),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: AppTheme.body(
                  size: 12.5,
                  color: AppColors.ink,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
