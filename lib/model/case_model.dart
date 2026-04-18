// class CaseModel {
//   final int? id;
//   final String? fullName;
//   final String? mediaUrl;
//   final String? reward;
//   final String? description; // Add this
//   final dynamic caseType;
//   final dynamic kebele;

//   CaseModel({
//     this.id,
//     this.fullName,
//     this.mediaUrl,
//     this.reward,
//     this.description, // Add this
//     this.caseType,
//     this.kebele,
//   });

//   // This getter handles the "kebeleName" error by safely reaching into the kebele object
//   String get kebeleName =>
//       (kebele is Map) ? (kebele['name'] ?? "Unknown") : "Unknown";

//   factory CaseModel.fromJson(Map<String, dynamic> json) {
//     return CaseModel(
//       id: json['id'],
//       fullName: json['fullName'],
//       mediaUrl: json['mediaUrl'],
//       reward: json['reward']?.toString(),
//       description: json['description'], // Map from JSON
//       caseType: json['caseType'],
//       kebele: json['kebele'] ?? json['Kebele'],
//     );
//   }
// }
