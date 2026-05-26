import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../model/service_type.dart';

class ServiceTypeService {
  // 🔥 SET TO 'true' to develop locally. SET TO 'false' to use live Render server.
  static const bool useLocalBackup = false;

  // 🌍 Dynamic Origin URL Router
  static String get baseUrl {
    if (!useLocalBackup) {
      return "https://bahirlink-backend-1.onrender.com/api/serviceType";
    }
    if (kIsWeb) {
      return "http://localhost:5000/api/serviceType";
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:5000/api/serviceType"; // Android Emulator address
    } else {
      return "http://localhost:5000/api/serviceType"; // iOS Simulator or Desktop
    }
  }

  // ── FETCH ALL SERVICE TYPES ────────────────────────────────────────────────
  static Future<List<ServiceType>> getAllServiceTypes(
      {String lang = 'en'}) async {
    try {
      // Append 'lang' as a query parameter for the backend localization helper
      final Uri url = Uri.parse(baseUrl).replace(queryParameters: {
        'lang': lang,
      });

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Accept-Language':
              lang, // Crucial for backend localization mapping (en/am)
        },
      ).timeout(const Duration(
          seconds: 60)); // Extended to 60s for Render free-tier cold starts

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Safely extract list elements from the standardized 'data' wrapper key
        if (responseData['success'] == true && responseData['data'] is List) {
          final List list = responseData['data'];
          return list
              .map((e) => ServiceType.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
      } else {
        debugPrint("❌ ServiceTypeService Error: ${response.statusCode}");
        return [];
      }
    } on SocketException {
      debugPrint("❌ Connection Error: Server is unreachable");
      return [];
    } catch (e) {
      debugPrint("❌ ServiceTypeService Exception: $e");
      return [];
    }
  }
}
