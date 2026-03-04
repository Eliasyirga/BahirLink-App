class EmergencyReportModel {
  final String type;
  final String description;
  final double? latitude;
  final double? longitude;
  final String? deviceId;
  final String? phone; // guest contactNo
  final int? userId; // logged-in user ID
  final String? location;

  EmergencyReportModel({
    required this.type,
    required this.description,
    this.latitude,
    this.longitude,
    this.deviceId,
    this.phone,
    this.userId,
  }) : location = (latitude != null && longitude != null)
           ? "$latitude,$longitude"
           : null;

  // JSON for guest
  Map<String, dynamic> toJson({bool useContactNo = false}) {
    final data = <String, dynamic>{
      "emergencyType": type,
      "description": description,
      "location": location ?? "",
      "deviceId": deviceId ?? "",
    };
    if (useContactNo && phone != null) data["contactNo"] = phone;
    return data;
  }

  // JSON for logged-in user
  Map<String, dynamic> toJsonForUser() {
    return {
      "emergencyType": type,
      "description": description,
      "location": location ?? "",
      "userId": userId,
    };
  }
}
