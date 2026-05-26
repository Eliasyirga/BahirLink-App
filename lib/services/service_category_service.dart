import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ServiceCategoryService {
  // 🔥 SET TO 'true' to develop locally. SET TO 'false' to use live Render server.
  static const bool useLocalBackup = false;

  // ── Base URL ───────────────────────────────────────────────────────────────
  static String get serverUrl {
    if (!useLocalBackup) {
      return "https://bahirlink-backend-1.onrender.com";
    }
    if (kIsWeb) return "http://localhost:5000";
    if (Platform.isAndroid)
      return "http://10.0.2.2:5000"; // Android Emulator address
    return "http://localhost:5000"; // iOS Simulator or Desktop
  }

  static String get baseUrl => "$serverUrl/api/serviceCategory";

  // ── GET CATEGORIES BY SERVICE TYPE ─────────────────────────────────────────
  /// Fetch categories for a specific service type ID with localization.
  /// Backend resolves the locale via the Accept-Language header —
  /// every item's [name] is a plain resolved string, just like CategoryService.
  static Future<List<dynamic>> getCategoriesByServiceType(
    String serviceTypeId, {
    String lang = 'en',
  }) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/type/$serviceTypeId"),
        headers: {
          "Content-Type": "application/json",
          "Accept-Language": lang, // Crucial for localization logic
        },
      ).timeout(const Duration(
          seconds: 60)); // Extended to 60s for Render free-tier cold starts

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        final List<dynamic> data = switch (decoded) {
          Map d when d.containsKey('data') => d['data'] as List? ?? [],
          Map d when d.containsKey('categories') =>
            d['categories'] as List? ?? [],
          List l => l,
          _ => [],
        };

        return data;
      } else {
        debugPrint("Backend Error: ${response.body}");
        return [];
      }
    } on SocketException {
      debugPrint("❌ ServiceCategoryService: Server unreachable.");
      return [];
    } catch (e) {
      debugPrint("Network Error: $e");
      return []; // Return an empty array gracefully to prevent UI thread crashes
    }
  }

  // ── GET CATEGORIES BY AGENCY ───────────────────────────────────────────────
  /// Fetch categories for a specific agency.
  static Future<List<dynamic>> getCategoriesByAgency(
    String agencyId, {
    String lang = 'en',
  }) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/by-agency/$agencyId"),
        headers: {
          "Content-Type": "application/json",
          "Accept-Language": lang,
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded["data"] ?? [];
      }
      debugPrint("Backend Error: ${response.body}");
      return [];
    } on SocketException {
      debugPrint("❌ ServiceCategoryService: Server unreachable.");
      return [];
    } catch (e) {
      debugPrint("Network Error: $e");
      return [];
    }
  }
}
