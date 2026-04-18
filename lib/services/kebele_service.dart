import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class KebeleService {
  final String _baseUrl = "http://localhost:5000/api/kebele";

  Future<List<Map<String, dynamic>>> getAllKebeles() async {
    try {
      final response = await http
          .get(Uri.parse(_baseUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Handle different backend response structures
        List<dynamic> list;
        if (data is List) {
          list = data;
        } else if (data is Map && data['kebeles'] != null) {
          list = data['kebeles'];
        } else {
          return [];
        }

        return list
            .map(
              (k) => {
                'id': k['id'], // Ensure this matches your DB key (id or _id)
                'name': k['name'],
              },
            )
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching kebeles: $e");
      return [];
    }
  }
}
