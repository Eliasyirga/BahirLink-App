import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class KebeleService {
  // 🌍 Dynamic Origin URL Router
  String get _baseUrl => "${ApiConfig.baseUrl}/api/kebele";

  // ── GET ALL KEBELES ────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getAllKebeles() async {
    try {
      final response = await http
          .get(Uri.parse(_baseUrl))
          // Extended to 60s to handle Render free-tier environment initialization delays
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Handle different backend response structures safely
        List<dynamic> list;
        if (data is List) {
          list = data;
        } else if (data is Map && data['kebeles'] != null) {
          list = data['kebeles'];
        } else if (data is Map && data['data'] != null) {
          // Added a fallback for your standardized 'data' key payload wrapper
          list = data['data'];
        } else {
          return [];
        }

        return list
            .map(
              (k) => {
                'id': k['id'] ??
                    k['_id'], // Tolerates both SQL IDs and MongoDB ObjectIDs
                'name': k['name'],
              },
            )
            .toList();
      }
      return [];
    } on SocketException {
      debugPrint("❌ KebeleService: Server unreachable.");
      return [];
    } catch (e) {
      debugPrint("❌ Error fetching kebeles: $e");
      return [];
    }
  }
}
