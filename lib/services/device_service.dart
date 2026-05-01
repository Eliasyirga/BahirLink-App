import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'dart:io' show Platform;

class DeviceService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static Future<String?> getDeviceId() async {
    try {
      if (kIsWeb) {
        // ⚠️ better fallback web ID (stable per session)
        return "web-user";
      }

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;

        // safer fallback chain
        return androidInfo.id ?? androidInfo.model ?? androidInfo.brand;
      }

      if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;

        return iosInfo.identifierForVendor ?? iosInfo.name ?? iosInfo.model;
      }
    } catch (e) {
      debugPrint("Device ID Error: $e");
    }

    return null;
  }
}
