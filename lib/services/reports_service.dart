import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ReportsService {
  // Use 10.0.2.2 for Android Emulator, localhost for Web/iOS
  static const String baseUrl = "http://localhost:5000/api";

  static Map<String, String> _getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ---------------- Fetch Emergencies ----------------
  static Future<List<Map<String, dynamic>>> fetchUserEmergencies(
    String id, {
    String? token,
    bool isGuest = false,
  }) async {
    // Backend expects guestId in query params: /api/emergencies/:id?guestId=true
    final url = Uri.parse(
      "$baseUrl/emergencies/$id${isGuest ? '?guestId=true' : ''}",
    );
    final response = await http.get(url, headers: _getHeaders(token));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      // Your backend returns { success: true, data: [...] }
      return List<Map<String, dynamic>>.from(jsonResponse['data'] ?? []);
    } else {
      throw Exception("Failed to load emergencies: ${response.body}");
    }
  }

  // ---------------- Fetch Emergency Types ----------------
  static Future<List<Map<String, dynamic>>> fetchEmergencyTypes({
    String? token,
  }) async {
    final url = Uri.parse("$baseUrl/emergencyType");
    final response = await http.get(url, headers: _getHeaders(token));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      // Backend handling for both list and wrapped object
      if (jsonResponse is List)
        return List<Map<String, dynamic>>.from(jsonResponse);
      return List<Map<String, dynamic>>.from(
        jsonResponse['emergencyTypes'] ?? [],
      );
    }
    throw Exception("Failed to load emergency types");
  }

  // ---------------- Fetch Categories ----------------
  static Future<List<Map<String, dynamic>>> fetchCategories({
    String? token,
  }) async {
    final url = Uri.parse("$baseUrl/categories");
    final response = await http.get(url, headers: _getHeaders(token));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(
        jsonResponse is List ? jsonResponse : (jsonResponse['data'] ?? []),
      );
    }
    throw Exception("Failed to load categories");
  }

  // ---------------- Update Emergency (Web + Mobile) ----------------
  static Future<Map<String, dynamic>> updateEmergency(
    String userOrGuestId,
    String emergencyId,
    Map<String, dynamic> updatedData, {
    File? file,
    Uint8List? webBytes,
    String? fileName,
    String? token,
    bool isGuest = false,
  }) async {
    final uri = Uri.parse("$baseUrl/emergencies/$userOrGuestId/$emergencyId");
    final request = http.MultipartRequest('PUT', uri);

    // Add Authorization if token exists
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Backend updateEmergencyHandler uses req.body.guestId to determine role
    if (isGuest) {
      request.fields['guestId'] = userOrGuestId;
    }

    // Add data fields (location, description, kebele, etc.)
    updatedData.forEach((key, value) {
      if (value != null) {
        if (value is Map || value is List) {
          request.fields[key] = jsonEncode(value);
        } else {
          request.fields[key] = value.toString();
        }
      }
    });

    // Add file (media)
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
      final decoded = jsonDecode(response.body);
      return Map<String, dynamic>.from(decoded['data'] ?? decoded);
    } else {
      throw Exception("Update failed: ${response.body}");
    }
  }

  // ---------------- Delete Emergency ----------------
  static Future<void> deleteEmergency(
    String userOrGuestId,
    String emergencyId, {
    String? token,
    bool isGuest = false,
  }) async {
    final url = Uri.parse("$baseUrl/emergencies/$userOrGuestId/$emergencyId");

    // Backend delete handler expects isGuest indicator if applicable
    final response = await http.delete(
      url,
      headers: _getHeaders(token),
      body: isGuest ? jsonEncode({'guestId': userOrGuestId}) : null,
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to delete emergency: ${response.body}");
    }
  }
}
