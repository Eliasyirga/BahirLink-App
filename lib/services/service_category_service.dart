import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ServiceCategoryService {
  // Use 10.0.2.2 for Android Emulator, 127.0.0.1 for iOS, or your Local IP for physical devices
  static const String baseUrl = "http://localhost:5000/api/serviceCategory";

  /// Fetches service categories based on a specific Service Type ID.
  static Future<List<Map<String, dynamic>>> getCategoriesByServiceType(
    String serviceTypeId,
  ) async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/type/$serviceTypeId"))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ✅ Backend standard: { success: true, count: X, data: [...] }
        List<dynamic> rawList = [];
        if (data is Map && data.containsKey("data")) {
          rawList = data["data"];
        } else if (data is Map && data.containsKey("categories")) {
          rawList = data["categories"];
        } else if (data is List) {
          rawList = data;
        }

        return rawList.map((item) {
          return {
            "id": item["id"]?.toString() ?? "",
            // ✅ CRITICAL: Do NOT use .toString() here. 
            // Keep it as a Map so you can do name['en'] or name['am']
            "name": item["name"], 
            "description": item["description"],
            "serviceTypeId": item["serviceTypeId"],
          };
        }).toList();
      } else {
        debugPrint("❌ ServiceCategory Server Error: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("❌ ServiceCategory Connection Exception: $e");
      return [];
    }
  }

  /// ✅ UI Helper: Selects English or Amharic from the category name
  static String getName(dynamic nameField, String langCode) {
    if (nameField == null) return "Unknown";
    if (nameField is Map) {
      return nameField[langCode]?.toString() ?? nameField['en']?.toString() ?? "";
    }
    return nameField.toString();
  }
}