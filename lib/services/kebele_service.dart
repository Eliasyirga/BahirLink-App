import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class KebeleService {
  // 🔥 SET TO 'true' to develop locally. SET TO 'false' to use live Render server.
  static const bool useLocalBackup = false;

  // 🌍 Dynamic Origin URL Router
  String get _baseUrl {
    if (!useLocalBackup) {
      return "https://bahirlink-backend-1.onrender.com/api/kebele";
    }
    if (kIsWeb) {
      return "http://localhost:5000/api/kebele";
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:5000/api/kebele"; // Android Emulator address
    } else {
      return "http://localhost:5000/api/kebele"; // iOS Simulator or Desktop
    }
  }

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
