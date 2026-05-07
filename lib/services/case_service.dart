import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CaseService {
  // Use 10.0.2.2 for Android Emulator, or your machine's IP for physical devices
  static const String _baseUrl = "http://localhost:5000/api/cases";

  /// Fetches filtered list of active cases with localization support
  static Future<List<dynamic>> getAllCases({String lang = 'en'}) async {
    try {
      // ✅ Append 'lang' as a query parameter
      final Uri url = Uri.parse(_baseUrl).replace(queryParameters: {
        'lang': lang,
      });

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Accept-Language': lang,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // ✅ Check for 'success' flag and extract from 'data' key
        if (responseData['success'] == true && responseData['data'] is List) {
          final List<dynamic> allCases = responseData['data'];

          // Filter Logic: Exclude 'rejected' and 'resolved' cases
          return allCases.where((c) {
            final status = (c['status'] ?? '').toString().toLowerCase();
            return status != 'rejected' && status != 'resolved';
          }).toList();
        }
        return [];
      } else {
        debugPrint("❌ CaseService Error: ${response.statusCode} - ${response.body}");
        return [];
      }
    } on SocketException {
      debugPrint("❌ Connection Error: Server unreachable (Check IP or Network)");
      return [];
    } catch (e) {
      debugPrint("❌ CaseService Exception: $e");
      return [];
    }
  }

  /// Simple null-check helper for UI display
  static String getDisplayText(dynamic value) {
    if (value == null) return "N/A";
    return value.toString();
  }
}