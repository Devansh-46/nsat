import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';


import '../../routes/app_routes.dart';
import '../../widgets/mesh_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/eyebrow.dart';
import '../../widgets/niu_button.dart';

import '../../services/remote_config_service.dart';


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
    await launchUrl(uri,
        mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');
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
              constraints: const BoxConstraints(maxWidth: 460),
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
                      const SizedBox(height: 24),
                      NiuButton(
                        label: 'Android phone / tablet',
                        variant: NiuButtonVariant.forest,
                        onTap: _chooseAndroid,
                      ),
                      const SizedBox(height: 12),
                      NiuButton(
                        label: 'iPhone / iPad',
                        variant: NiuButtonVariant.outline,
                        onTap: _chooseIos,
                      ),
                      const SizedBox(height: 12),
                      NiuButton(
                        label: 'Laptop / Desktop — continue in browser',
                        variant: NiuButtonVariant.primary,
                        onTap: _continueWeb,
                      ),
                      const SizedBox(height: 8),
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
