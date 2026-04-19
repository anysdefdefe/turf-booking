class Court {
  final String id;
  final String stadiumId;
  final String stadiumName;
  final String name;
  final String place;
  final String city;
  final String imageUrl;
  final double pricePerHour;
  final List<String> courtTypes;
  final bool isAvailable;
  final String description;
  final List<String> equipments;
  final String openTime;
  final String closeTime;
  final double distanceKm;
  final String teamSize;

  const Court({
    required this.id,
    required this.stadiumId,
    required this.stadiumName,
    required this.name,
    required this.place,
    required this.city,
    required this.imageUrl,
    required this.pricePerHour,
    required this.courtTypes,
    required this.isAvailable,
    required this.description,
    required this.equipments,
    required this.openTime,
    required this.closeTime,
    required this.distanceKm,
    required this.teamSize,
  });
}
