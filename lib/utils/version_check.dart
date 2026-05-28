import 'package:package_info_plus/package_info_plus.dart';
import '../services/remote_config_service.dart';

/// Checks if the current app version meets the minimum required version.
/// Returns true if the app is outdated and must be updated.
class VersionCheck {
  static Future<bool> isUpdateRequired() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionCode = int.tryParse(packageInfo.buildNumber) ?? 0;
      final minVersionCode = RemoteConfigService.instance.minVersionCode;

      return currentVersionCode < minVersionCode;
    } catch (_) {
      // If we can't determine version, don't block the user
      return false;
    }
  }
}
