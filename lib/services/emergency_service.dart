// import 'dart:typed_data';
// import 'dart:io' show File;
// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;
// import 'package:http_parser/http_parser.dart';
// import 'package:path/path.dart' as path;
// import 'package:mime/mime.dart';

// class EmergencyService {
//   // Use 10.0.2.2 for Android Emulator, or your actual IP for physical devices
//   static const String baseUrl = "http://localhost:5000/api";
//   static const String guestEmergencyEndpoint = "$baseUrl/emergencies/guests";

//   static Future<Map<String, dynamic>> createGuestEmergency({
//     required String contactNo,
//     required String kebele,
//     required String subdivision,
//     String? street,
//     String? description,
//     required String emergencyTypeId,
//     required String categoryId,
//     double? latitude,
//     double? longitude,
//     String? time,
//     Uint8List? mediaBytes,
//     File? mediaFile,
//     String? mediaName,
//   }) async {
//     try {
//       final request = http.MultipartRequest(
//         'POST',
//         Uri.parse(guestEmergencyEndpoint),
//       );

//       // 1. Map basic fields
//       final Map<String, String> fields = {
//         "contactNo": contactNo,
//         "kebele": kebele,
//         "subdivision": subdivision,
//         "emergencyTypeId": emergencyTypeId,
//         "categoryId": categoryId,
//         "time": time ?? DateTime.now().toIso8601String(),
//       };

//       if (street != null) fields["street"] = street;
//       if (description != null) fields["description"] = description;
//       if (latitude != null) fields["latitude"] = latitude.toString();
//       if (longitude != null) fields["longitude"] = longitude.toString();

//       request.fields.addAll(fields);

//       // 2. Handle Media (Web vs Mobile)
//       if (kIsWeb) {
//         if (mediaBytes != null && mediaName != null) {
//           _addMultipartFileWeb(request, mediaBytes, mediaName);
//         }
//       } else {
//         if (mediaFile != null) {
//           await _addMultipartFileMobile(request, mediaFile);
//         }
//       }

//       // 3. Send Request
//       final streamedResponse = await request.send().timeout(
//         const Duration(seconds: 30),
//       );
//       final response = await http.Response.fromStream(streamedResponse);

//       debugPrint("Emergency Report Status: ${response.statusCode}");

//       if (response.statusCode == 201 || response.statusCode == 200) {
//         final decoded = jsonDecode(response.body);
//         return {"success": true, "data": decoded};
//       } else {
//         return {
//           "success": false,
//           "message": "Server returned ${response.statusCode}: ${response.body}",
//         };
//       }
//     } catch (e) {
//       debugPrint("createGuestEmergency Exception: $e");
//       return {"success": false, "message": e.toString()};
//     }
//   }

//   // Helper for Web File Uploads
//   static void _addMultipartFileWeb(
//     http.MultipartRequest request,
//     Uint8List bytes,
//     String fileName,
//   ) {
//     final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';
//     final split = mimeType.split('/');

//     request.fields['mediaType'] = split.first == "video" ? "video" : "photo";

//     request.files.add(
//       http.MultipartFile.fromBytes(
//         'media',
//         bytes,
//         filename: fileName,
//         contentType: MediaType(split[0], split[1]),
//       ),
//     );
//   }

//   // Helper for Mobile File Uploads
//   static Future<void> _addMultipartFileMobile(
//     http.MultipartRequest request,
//     File file,
//   ) async {
//     final fileName = path.basename(file.path);
//     final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';
//     final split = mimeType.split('/');

//     request.fields['mediaType'] = split.first == "video" ? "video" : "photo";

//     request.files.add(
//       await http.MultipartFile.fromPath(
//         'media',
//         file.path,
//         contentType: MediaType(split[0], split[1]),
//       ),
//     );
//   }
// }
import 'dart:typed_data';
import 'dart:io' show File;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';

class EmergencyService {
  static const String baseUrl = "http://localhost:5000/api";
  static const String guestEmergencyEndpoint = "$baseUrl/emergencies/guests";

  static Future<Map<String, dynamic>> createGuestEmergency({
    required String contactNo,
    required String kebele,
    required String subdivision,
    String? street,
    String? description,
    required String emergencyTypeId,
    required String categoryId,
    double? latitude,
    double? longitude,
    String? time,

    // ✅ ADD THIS
    String? deviceId,
    Uint8List? mediaBytes,
    File? mediaFile,
    String? mediaName,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(guestEmergencyEndpoint),
      );

      // 1. Fields
      final Map<String, String> fields = {
        "contactNo": contactNo,
        "kebele": kebele,
        "subdivision": subdivision,
        "emergencyTypeId": emergencyTypeId,
        "categoryId": categoryId,
        "time": time ?? DateTime.now().toIso8601String(),
      };

      if (street != null) fields["street"] = street;
      if (description != null) fields["description"] = description;
      if (latitude != null) fields["latitude"] = latitude.toString();
      if (longitude != null) fields["longitude"] = longitude.toString();

      // ✅ ADD DEVICE ID TO REQUEST
      if (deviceId != null) {
        fields["deviceId"] = deviceId;
      }

      request.fields.addAll(fields);

      // 2. Media upload
      if (kIsWeb) {
        if (mediaBytes != null && mediaName != null) {
          _addMultipartFileWeb(request, mediaBytes, mediaName);
        }
      } else {
        if (mediaFile != null) {
          await _addMultipartFileMobile(request, mediaFile);
        }
      }

      // 3. Send request
      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 30));

      final response = await http.Response.fromStream(streamedResponse);

      debugPrint("Emergency Report Status: ${response.statusCode}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return {"success": true, "data": decoded};
      } else {
        return {
          "success": false,
          "message": "Server returned ${response.statusCode}: ${response.body}",
        };
      }
    } catch (e) {
      debugPrint("createGuestEmergency Exception: $e");
      return {"success": false, "message": e.toString()};
    }
  }

  static void _addMultipartFileWeb(
    http.MultipartRequest request,
    Uint8List bytes,
    String fileName,
  ) {
    final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';
    final split = mimeType.split('/');

    request.fields['mediaType'] = split.first == "video" ? "video" : "photo";

    request.files.add(
      http.MultipartFile.fromBytes(
        'media',
        bytes,
        filename: fileName,
        contentType: MediaType(split[0], split[1]),
      ),
    );
  }

  static Future<void> _addMultipartFileMobile(
    http.MultipartRequest request,
    File file,
  ) async {
    final fileName = path.basename(file.path);
    final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';
    final split = mimeType.split('/');

    request.fields['mediaType'] = split.first == "video" ? "video" : "photo";

    request.files.add(
      await http.MultipartFile.fromPath(
        'media',
        file.path,
        contentType: MediaType(split[0], split[1]),
      ),
    );
  }
}
