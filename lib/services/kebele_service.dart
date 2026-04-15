import 'dart:convert';
import 'package:http/http.dart' as http;

class KebeleService {
  // Use 10.0.2.2 if using Android Emulator, or your specific IP
  final String baseUrl = "http://localhost:5000/api/kebele";

  Future<List<Map<String, dynamic>>> getAllKebeles() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Assuming your backend returns { success: true, kebeles: [...] }
        // or just the list directly.
        final List<dynamic> kebeles = data is List
            ? data
            : data['kebeles'] ?? [];

        return kebeles.map((k) => {'id': k['id'], 'name': k['name']}).toList();
      } else {
        throw Exception('Failed to load kebeles');
      }
    } catch (e) {
      print("Error fetching kebeles: $e");
      return [];
    }
  }
}
