import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static Future<String?> getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;

        // Unique ID for Android
        return androidInfo.id;
      }

      if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;

        return iosInfo.identifierForVendor;
      }

      return null;
    } catch (e) {
      print("Device ID Error: $e");
      return null;
    }
  }
}
