import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ServiceReportService {
  // ✅ Base URL for the entire server to fetch assets
  static String get serverUrl {
    if (kIsWeb) return "http://localhost:5000";
    if (Platform.isAndroid) return "http://10.0.2.2:5000"; // Android Emulator
    return "http://localhost:5000"; // Physical devices (use your IP here)
  }

  final String apiUrl = "$serverUrl/api/service";

  /// ✅ HELPER: Converts DB path (/uploads/...) to a Full Network URL
  static String getFullImageUrl(String? partialPath) {
    if (partialPath == null || partialPath.isEmpty) return "";

    // If it's already a full URL (stored from a CDN), return it
    if (partialPath.startsWith('http')) return partialPath;

    // Combine Server IP with the DB path
    return "$serverUrl$partialPath";
  }

  Future<List<dynamic>> getUserServices(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/user/$userId'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['services'] ?? [];
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Failed to connect to backend: $e");
    }
  }
}
