class EmergencyReportModel {
  final String type;
  final String description;
  final String? location;
  final String? deviceId;

  EmergencyReportModel({
    required this.type,
    required this.description,
    this.location,
    this.deviceId,
  });

  Map<String, dynamic> toJson() {
    return {
      "emergencyType": type,
      "description": description,
      "location": location,
      "deviceId": deviceId,
    };
  }
}
