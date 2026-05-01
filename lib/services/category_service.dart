// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class CategoryService {
//   static const baseUrl = "http://localhost:5000/api/categories";

//   /// Fetch categories for a specific emergency type ID
//   static Future<List<dynamic>> getCategories(String emergencyTypeId) async {
//     final response = await http.get(
//       Uri.parse("$baseUrl/type/$emergencyTypeId"),
//     );

//     if (response.statusCode == 200) {
//       final decoded = jsonDecode(response.body);

//       // ✅ FIXED HERE
//       return decoded["data"] ?? [];
//     } else {
//       throw Exception("Failed to load categories");
//     }
//   }
// }
import 'dart:convert';
import 'package:http/http.dart' as http;

class CategoryService {
  static const baseUrl = "http://localhost:5000/api/categories";

  /// Fetch categories for a specific emergency type ID
  static Future<List<dynamic>> getCategories(String emergencyTypeId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/type/$emergencyTypeId"),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      // ✅ FIXED HERE
      return decoded["data"] ?? [];
    } else {
      throw Exception("Failed to load categories");
    }
  }
}
