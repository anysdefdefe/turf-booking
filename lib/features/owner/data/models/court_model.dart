class CourtModel {
  final String id;
  final String stadiumId;
  final String name;
  final String sportType;
  final String? description;
  final double pricePerHour;
  final String? imageUrl;
  final List<String> equipments;
  final String openTime;  // Stored as HH:mm:ss in Postgres
  final String closeTime; // Stored as HH:mm:ss in Postgres
  final bool isActive;
  final DateTime createdAt;

  const CourtModel({
    required this.id,
    required this.stadiumId,
    required this.name,
    required this.sportType,
    this.description,
    required this.pricePerHour,
    this.imageUrl,
    this.equipments = const [],
    required this.openTime,
    required this.closeTime,
    required this.isActive,
    required this.createdAt,
  });

  factory CourtModel.fromJson(Map<String, dynamic> json) {
    final rawEquipments = json['equipments'] ?? json['amenities'];
    final List<String> parsedEquipments = rawEquipments is List
        ? rawEquipments.map((item) => item.toString()).toList(growable: false)
        : const [];

    return CourtModel(
      id: json['id'] as String,
      stadiumId: json['stadium_id'] as String,
      name: json['name'] as String,
      sportType: json['sport_type'] as String,
      description: json['description'] as String?,
      pricePerHour: (json['price_per_hour'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
      equipments: parsedEquipments,
      openTime: json['open_time'] as String,
      closeTime: json['close_time'] as String,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] is String
          ? DateTime.parse(json['created_at'])
          : json['created_at'] as DateTime,
    );
  }

  /// Insert payload. [openTime] and [closeTime] are inherited from the
  /// stadium-level timings set by the owner in the UI.
  Map<String, dynamic> toInsertJson() {
    return {
      'stadium_id': stadiumId,
      'name': name,
      'sport_type': sportType,
      'description': description,
      'price_per_hour': pricePerHour,
      'image_url': null, // No image uploads for MVP
      'equipments': equipments,
      'open_time': openTime,
      'close_time': closeTime,
      'is_active': isActive,
    };
  }
}
