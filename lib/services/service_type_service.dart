import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ServiceTypeService {
  // Use 10.0.2.2 if testing on an Android Emulator, or your local IP if on a physical device
  static const String baseUrl = "http://localhost:5000/api/serviceType";

  static Future<List<dynamic>> getAllServiceTypes() async {
    try {
      final response = await http
          .get(Uri.parse(baseUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Ensure we are specifically targeting the list inside the response
        final List<dynamic>? serviceTypes = data["serviceTypes"];

        return serviceTypes ?? [];
      } else {
        debugPrint("Server Error: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Network or Parsing Error: $e");
      // Returning an empty list ensures .isEmpty works in the UI
      return [];
    }
  }
}
