import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_logger.dart';

/// Captures device metadata at test start and stores it in the attempt doc.
/// Used for post-exam auditing — if the same student shows different
/// device info across sessions, it's a red flag.
class DeviceFingerprintService {
  static const _tag = 'DeviceFingerprint';
  final _log = AppLogger.instance;
  final _deviceInfo = DeviceInfoPlugin();

  /// Collects device info and writes it to the attempt document.
  /// Call this right after the attempt lock is claimed in test_provider.
  Future<void> captureAndStore(String applicationNo) async {
    try {
      final fingerprint = await _collectFingerprint();

      await FirebaseFirestore.instance
          .collection('device_fingerprints')
          .doc(applicationNo)
          .set({
        ...fingerprint,
        'capturedAt': FieldValue.serverTimestamp(),
      });

      _log.info(_tag, 'Device fingerprint stored for $applicationNo');
    } catch (e, st) {
      // Non-critical — don't block the test if this fails
      _log.error(_tag, 'Failed to capture device fingerprint: $e',
          error: e, stackTrace: st);
    }
  }

  Future<Map<String, dynamic>> _collectFingerprint() async {
    if (kIsWeb) {
      final webInfo = await _deviceInfo.webBrowserInfo;
      return {
        'platform': 'web',
        'browserName': webInfo.browserName.name,
        'userAgent': webInfo.userAgent ?? 'unknown',
        'language': webInfo.language ?? 'unknown',
        'languages': webInfo.languages ?? [],
        'vendor': webInfo.vendor ?? 'unknown',
        'hardwareConcurrency': webInfo.hardwareConcurrency ?? 0,
        'maxTouchPoints': webInfo.maxTouchPoints ?? 0,
        'screenWidth': 0, // Will be filled by web-specific code if needed
        'screenHeight': 0,
      };
    } else if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      return {
        'platform': 'android',
        'brand': androidInfo.brand,
        'model': androidInfo.model,
        'device': androidInfo.device,
        'androidVersion': androidInfo.version.release,
        'sdkInt': androidInfo.version.sdkInt,
        'manufacturer': androidInfo.manufacturer,
        'fingerprint': androidInfo.fingerprint,
        'isPhysicalDevice': androidInfo.isPhysicalDevice,
        'display': androidInfo.display,
      };
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      return {
        'platform': 'ios',
        'name': iosInfo.name,
        'model': iosInfo.model,
        'systemName': iosInfo.systemName,
        'systemVersion': iosInfo.systemVersion,
        'isPhysicalDevice': iosInfo.isPhysicalDevice,
        'utsname': iosInfo.utsname.machine,
      };
    }

    return {'platform': 'unknown'};
  }
}
