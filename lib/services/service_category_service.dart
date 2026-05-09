import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ServiceCategoryService {
  static String get serverUrl {
    if (kIsWeb) return "http://localhost:5000";
    if (Platform.isAndroid) return "http://10.0.2.2:5000";
    return "http://localhost:5000";
  }

  static String get baseUrl => "$serverUrl/api/serviceCategory";

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
          "Content-Type"   : "application/json",
          "Accept-Language": lang,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        final List<dynamic> data = switch (decoded) {
          Map d when d.containsKey('data')       => d['data']       as List? ?? [],
          Map d when d.containsKey('categories') => d['categories'] as List? ?? [],
          List l                                 => l,
          _                                      => [],
        };

        return data;
      } else {
        debugPrint("Backend Error: ${response.body}");
        return [];
      }
    } catch (e) {
      debugPrint("Network Error: $e");
      throw Exception("Could not connect to the server.");
    }
  }

  /// Fetch categories for a specific agency.
  static Future<List<dynamic>> getCategoriesByAgency(
    String agencyId, {
    String lang = 'en',
  }) async {
    final response = await http.get(
      Uri.parse("$baseUrl/by-agency/$agencyId"),
      headers: {"Accept-Language": lang},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded["data"] ?? [];
    }
    return [];
  }
}