import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CaseService {
  static const String _baseUrl = "http://localhost:5000/api/cases";

  static Future<List<dynamic>> getAllCases({String lang = 'en'}) async {
    try {
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

        if (responseData['success'] == true && responseData['data'] is List) {
          final List<dynamic> allCases = responseData['data'];

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

  static Future<dynamic> getCaseById({
    required String id,
    String lang = 'en',
  }) async {
    try {
      final Uri url = Uri.parse("$_baseUrl/$id").replace(queryParameters: {
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

        if (responseData['success'] == true && responseData['data'] != null) {
          return responseData['data'];
        }
        return responseData;
      } else {
        debugPrint("❌ getCaseById Error: ${response.statusCode} - ${response.body}");
        return null;
      }
    } on SocketException {
      debugPrint("❌ Connection Error: Server unreachable");
      return null;
    } catch (e) {
      debugPrint("❌ getCaseById Exception: $e");
      return null;
    }
  }

  /// Extracts kebele/location name from a case object, trying all known shapes
  static String extractKebele(dynamic caseData, {String fallback = 'Location Not Set'}) {
    // Shape 1: { "lastSeenLocation": { "name": "..." } }
    final lastSeenLocation = caseData['lastSeenLocation'];
    if (lastSeenLocation is Map) {
      if (lastSeenLocation['name'] != null &&
          lastSeenLocation['name'].toString().isNotEmpty) {
        return lastSeenLocation['name'].toString();
      }
      final kebele = lastSeenLocation['Kebele'] ?? lastSeenLocation['kebele'];
      if (kebele is Map && kebele['name'] != null &&
          kebele['name'].toString().isNotEmpty) {
        return kebele['name'].toString();
      }
    }

    // Shape 2: legacy nested { "Kebele": { "name": "..." } }
    final kebele = caseData['Kebele'] ?? caseData['kebele'];
    if (kebele is Map && kebele['name'] != null &&
        kebele['name'].toString().isNotEmpty) {
      return kebele['name'].toString();
    }

    // Shape 3: flat string fields
    for (final key in ['kebele_name', 'kebeleId', 'kebele_id', 'KebeleId']) {
      final val = caseData[key];
      if (val != null && val.toString().isNotEmpty) return val.toString();
    }

    return fallback;
  }

  static String getDisplayText(dynamic value) {
    if (value == null) return "N/A";
    return value.toString();
  }
}