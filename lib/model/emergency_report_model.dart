class EmergencyReportModel {
  final String type;
  final String description;
  final double? latitude;
  final double? longitude;
  final String? deviceId;
  final String? phone; // Guest contact number
  final int? userId; // Logged-in user ID
  final String? category; // Emergency category
  final String? kebele; // Added kebele
  final String? subdivision; // Added subdivision
  final String? street; // Added street
  final DateTime? time; // Time of emergency/report
  final String? location; // Computed from latitude/longitude

  EmergencyReportModel({
    required this.type,
    required this.description,
    this.latitude,
    this.longitude,
    this.deviceId,
    this.phone,
    this.userId,
    this.category,
    this.kebele,
    this.subdivision,
    this.street,
    DateTime? time,
  }) : time = time ?? DateTime.now(),
       location = (latitude != null && longitude != null)
           ? "$latitude,$longitude"
           : null;

  // ---------------- JSON for guest submission ----------------
  Map<String, dynamic> toJson({bool useContactNo = false}) {
    final data = <String, dynamic>{
      "emergencyType": type,
      "description": description,
      "location": location ?? "",
      "deviceId": deviceId ?? "",
      "category": category ?? "",
      "kebele": kebele ?? "",
      "subdivision": subdivision ?? "",
      "street": street ?? "",
      "time": time?.toIso8601String(),
    };
    if (useContactNo && phone != null) data["contactNo"] = phone;
    return data;
  }

  // ---------------- JSON for logged-in user submission ----------------
  Map<String, dynamic> toJsonForUser() {
    return {
      "emergencyType": type,
      "description": description,
      "location": location ?? "",
      "userId": userId,
      "category": category ?? "",
      "kebele": kebele ?? "",
      "subdivision": subdivision ?? "",
      "street": street ?? "",
      "time": time?.toIso8601String(),
    };
  }
}
