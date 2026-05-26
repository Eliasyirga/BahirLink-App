import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'dart:io' show Platform;

class DeviceService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Fetches a unique hardware or platform identifier.
  /// Crucial for tying anonymous case reports or notifications to a unique handset on Render.
  static Future<String?> getDeviceId() async {
    try {
      // 🌐 WEB ROUTE
      if (kIsWeb) {
        final webBrowserInfo = await _deviceInfo.webBrowserInfo;
        // Using a combination of browser features to make a more stable, unique string
        return "web-${webBrowserInfo.userAgent.hashCode}-${webBrowserInfo.vendor}";
      }

      // 🤖 PHYSICAL OR EMULATED ANDROID ROUTE
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;

        // 'androidId' or hardware 'id' are the gold standard for unique device tracking
        // Fallback sequentially to model or hardware fingerprints if fields are null
        return androidInfo.id ??
            androidInfo.model ??
            androidInfo.hardware ??
            "unknown-android";
      }

      // 🍏 PHYSICAL OR EMULATED IOS ROUTE
      if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;

        // identifierForVendor is steady, persistent, and survives app updates
        return iosInfo.identifierForVendor ??
            iosInfo.name ??
            iosInfo.model ??
            "unknown-ios";
      }
    } catch (e) {
      debugPrint("❌ Device Info Extraction Error: $e");
    }

    return "fallback-device-id";
  }
}
