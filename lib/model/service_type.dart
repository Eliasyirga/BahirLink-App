class ServiceType {
  final int    id;
  final String nameEn;
  final String nameAm;

  const ServiceType({
    required this.id,
    required this.nameEn,
    required this.nameAm,
  });

  String localizedName(String lang) => lang == 'am' ? nameAm : nameEn;
  String get name => nameEn;

  factory ServiceType.fromJson(Map<String, dynamic> json) {
    String en = '';
    String am = '';

    final raw = json['name'];
    if (raw is Map) {
      // Backend returns { "en": "...", "am": "..." }
      en = raw['en']?.toString() ?? '';
      am = raw['am']?.toString() ?? '';
    } else if (raw is String) {
      // Backend already resolved it to a plain string via Accept-Language
      en = raw;
      am = raw;
    }

    return ServiceType(
      id:     json['id'] is int ? json['id'] as int
                                : int.tryParse(json['id'].toString()) ?? 0,
      nameEn: en,
      nameAm: am,
    );
  }
}