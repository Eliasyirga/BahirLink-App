import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ReportsService {
  static const String baseUrl = "http://localhost:5000/api";

  // ---------------- Fetch Emergencies ----------------
  static Future<List<Map<String, dynamic>>> fetchUserEmergencies(
    String userId,
  ) async {
    final url = Uri.parse("$baseUrl/emergencies/$userId");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse is List) {
        return List<Map<String, dynamic>>.from(jsonResponse);
      } else if (jsonResponse is Map && jsonResponse['data'] is List) {
        return List<Map<String, dynamic>>.from(jsonResponse['data']);
      }
      return [];
    } else {
      throw Exception("Failed to load emergencies (${response.statusCode})");
    }
  }

  // ---------------- Fetch Emergency Types ----------------
  static Future<List<Map<String, dynamic>>> fetchEmergencyTypes() async {
    final url = Uri.parse("$baseUrl/emergencyType");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse is List) {
        return List<Map<String, dynamic>>.from(jsonResponse);
      } else if (jsonResponse is Map &&
          jsonResponse['emergencyTypes'] is List) {
        return List<Map<String, dynamic>>.from(jsonResponse['emergencyTypes']);
      }
      return [];
    } else {
      throw Exception(
        "Failed to load emergency types (${response.statusCode})",
      );
    }
  }

  // ---------------- Fetch Categories ----------------
  static Future<List<Map<String, dynamic>>> fetchCategories() async {
    final url = Uri.parse("$baseUrl/categories");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse is List) {
        return List<Map<String, dynamic>>.from(jsonResponse);
      }
      return [];
    } else {
      throw Exception("Failed to load categories (${response.statusCode})");
    }
  }

  // ---------------- Update Emergency (Web + Mobile) ----------------
  static Future<Map<String, dynamic>> updateEmergency(
    String userId,
    String emergencyId,
    Map<String, dynamic> updatedData, {
    File? file, // Mobile
    Uint8List? webBytes, // Web
    String? fileName, // Web filename
  }) async {
    final uri = Uri.parse("$baseUrl/emergencies/$userId/$emergencyId");
    final request = http.MultipartRequest('PUT', uri);

    // Add fields
    updatedData.forEach((key, value) {
      request.fields[key] = value.toString();
    });

    // Add file
    if (kIsWeb && webBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'media',
          webBytes,
          filename: fileName ?? "upload.jpg",
        ),
      );
    } else if (!kIsWeb && file != null) {
      request.files.add(await http.MultipartFile.fromPath('media', file.path));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        "Failed to update emergency (${response.statusCode}): ${response.body}",
      );
    }
  }

  // ---------------- Delete Emergency ----------------
  static Future<void> deleteEmergency(String userId, String emergencyId) async {
    final url = Uri.parse("$baseUrl/emergencies/$userId/$emergencyId");
    final response = await http.delete(url);

    if (response.statusCode != 200) {
      throw Exception("Failed to delete emergency (${response.statusCode})");
    }
  }
}
