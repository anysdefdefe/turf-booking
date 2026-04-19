class CourtModel {
  final String id;
  final String stadiumId;
  final String name;
  final String sportType;
  final String? description;
  final double pricePerHour;
  final String? imageUrl;
  final List<String> amenities;
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
    this.amenities = const [],
    required this.openTime,
    required this.closeTime,
    required this.isActive,
    required this.createdAt,
  });

  factory CourtModel.fromJson(Map<String, dynamic> json) {
    // Postgres text[] arrives as List<dynamic>
    final rawAmenities = json['amenities'];
    final List<String> parsedAmenities = rawAmenities is List
        ? rawAmenities.cast<String>()
        : const [];

    return CourtModel(
      id: json['id'] as String,
      stadiumId: json['stadium_id'] as String,
      name: json['name'] as String,
      sportType: json['sport_type'] as String,
      description: json['description'] as String?,
      pricePerHour: (json['price_per_hour'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
      amenities: parsedAmenities,
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
      'amenities': amenities,
      'open_time': openTime,
      'close_time': closeTime,
      'is_active': isActive,
    };
  }
}
