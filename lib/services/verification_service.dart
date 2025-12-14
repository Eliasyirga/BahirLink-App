import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class VerificationService {
  final String baseUrl;

  VerificationService({required this.baseUrl});

  /// Upload ID image + selfie for verification
  Future<Map<String, dynamic>> verify({
    required File idImage,
    required File selfie,
  }) async {
    final uri = Uri.parse('$baseUrl/api/verify');
    final request = http.MultipartRequest('POST', uri);

    request.files.add(
      await http.MultipartFile.fromPath(
        'id_image',
        idImage.path,
        filename: path.basename(idImage.path),
      ),
    );

    request.files.add(
      await http.MultipartFile.fromPath(
        'selfie',
        selfie.path,
        filename: path.basename(selfie.path),
      ),
    );

    final response = await request.send();
    final respStr = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return jsonDecode(respStr);
    } else {
      return {'error': 'Server error ${response.statusCode}', 'body': respStr};
    }
  }
}
