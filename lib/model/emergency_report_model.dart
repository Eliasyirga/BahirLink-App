class EmergencyReportModel {
  final String type;
  final String description;
  final String? location;
  final String? deviceId;
  final String? phone;
  final String? mediaPath; // ✅ Added to support attached photo/video

  EmergencyReportModel({
    required this.type,
    required this.description,
    this.location,
    this.deviceId,
    this.phone,
    this.mediaPath, // ✅ Include in constructor
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      "type": type,
      "description": description,
      "location": location,
      "deviceId": deviceId,
      "phone": phone,
      "mediaPath": mediaPath, // ✅ Include in JSON
    };
  }
}
