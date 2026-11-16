import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../model/emergency_type.dart';
import '../config/api_config.dart';

class EmergencyTypeService {
  // 🌍 Dynamic Origin URL Router
  static String get baseUrl => "${ApiConfig.baseUrl}/api/emergencyType";

  // ── FETCH EMERGENCY TYPES ──────────────────────────────────────────────────
  static Future<List<EmergencyType>> fetchEmergencyTypes(
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
          'Accept-Language': lang, // Crucial for localization mapping (en/am)
        },
      ).timeout(const Duration(
          seconds: 60)); // Extended to 60s for Render free-tier cold starts

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Extract from 'data' key & check success status safely
        if (responseData['success'] == true && responseData['data'] is List) {
          final List list = responseData['data'];
          return list
              .map((e) => EmergencyType.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
      } else {
        debugPrint("❌ EmergencyTypeService Error: ${response.statusCode}");
        return [];
      }
    } on SocketException {
      debugPrint("❌ Connection Error: Server is unreachable");
      return [];
    } catch (e) {
      debugPrint("❌ EmergencyTypeService Exception: $e");
      return [];
    }
  }
}
