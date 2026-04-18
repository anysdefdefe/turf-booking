import '../models/court_model.dart';
import '../models/stadium_model.dart';

class CourtRepository {
  CourtRepository._();
  static final CourtRepository instance = CourtRepository._();

  final List<Stadium> _stadiums = [
    Stadium(
      id: 'std-001',
      ownerId: 'owner-001',
      name: 'Andheri Sports Dome',
      description:
          'Indoor premium complex with badminton and squash courts for all skill levels.',
      address: 'Andheri Sports Complex, SV Road',
      city: 'Andheri West',
      latitude: 19.1197,
      longitude: 72.8468,
      imageUrl:
          'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=1200&q=80',
      isActive: true,
      createdAt: DateTime(2025, 1, 10),
    ),
    Stadium(
      id: 'std-002',
      ownerId: 'owner-002',
      name: 'Powai Racket Arena',
      description:
          'Open-air and covered courts with coaching, night lights, and equipment rental.',
      address: 'Powai Lake Area, Main Access Road',
      city: 'Powai',
      latitude: 19.1176,
      longitude: 72.9060,
      imageUrl:
          'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=1200&q=80',
      isActive: true,
      createdAt: DateTime(2025, 2, 2),
    ),
    Stadium(
      id: 'std-003',
      ownerId: 'owner-003',
      name: 'Bandra Multi-Sport Hub',
      description:
          'Multi-sport venue with basketball, futsal, and volleyball courts under one roof.',
      address: 'Bandra Reclamation, Sports Lane',
      city: 'Bandra West',
      latitude: 19.0582,
      longitude: 72.8295,
      imageUrl:
          'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=1200&q=80',
      isActive: true,
      createdAt: DateTime(2025, 2, 24),
    ),
    Stadium(
      id: 'std-004',
      ownerId: 'owner-004',
      name: 'Seaside Sports Club',
      description:
          'Water-front sports complex with cricket nets, swimming lanes, and indoor training spaces.',
      address: 'Marine Drive Promenade, Block B',
      city: 'South Mumbai',
      latitude: 18.9440,
      longitude: 72.8235,
      imageUrl:
          'https://images.unsplash.com/photo-1547347298-4074fc3086f0?w=1200&q=80',
      isActive: true,
      createdAt: DateTime(2025, 3, 12),
    ),
  ];

  final List<Court> _courts = const [
    Court(
      id: '1',
      stadiumId: 'std-001',
      stadiumName: 'Andheri Sports Dome',
      name: 'Court 1 - Badminton Pro',
      place: 'Andheri Sports Complex',
      city: 'Andheri West',
      imageUrl:
          'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800&q=80',
      rating: 4.8,
      reviewCount: 234,
      pricePerHour: 600,
      courtTypes: ['Badminton', 'Squash'],
      isAvailable: true,
      description:
          'State-of-the-art badminton facility with 6 professional courts, wooden flooring, and high-speed shuttles. Perfect for casual play and tournaments alike.',
      amenities: [
        'Parking',
        'Changing Room',
        'Cafeteria',
        'AC Courts',
        'Equipment Rental',
      ],
      openTime: '06:00 AM',
      closeTime: '11:00 PM',
      distanceKm: 1.2,
      teamSize: 'Singles',
    ),
    Court(
      id: '2',
      stadiumId: 'std-001',
      stadiumName: 'Andheri Sports Dome',
      name: 'Court 2 - Squash Elite',
      place: 'Andheri Sports Complex',
      city: 'Andheri West',
      imageUrl:
          'https://images.unsplash.com/photo-1592656094267-764a45160876?w=800&q=80',
      rating: 4.6,
      reviewCount: 154,
      pricePerHour: 650,
      courtTypes: ['Squash'],
      isAvailable: true,
      description:
          'Professional squash court with cushioned flooring, live score panel, and modern ventilation.',
      amenities: ['Parking', 'Changing Room', 'AC Courts', 'Equipment Rental'],
      openTime: '06:00 AM',
      closeTime: '11:00 PM',
      distanceKm: 1.4,
      teamSize: 'Singles',
    ),
    Court(
      id: '3',
      stadiumId: 'std-002',
      stadiumName: 'Powai Racket Arena',
      name: 'Court A - Tennis Outdoor',
      place: 'Powai Lake Area',
      city: 'Powai',
      imageUrl:
          'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=800&q=80',
      rating: 4.5,
      reviewCount: 189,
      pricePerHour: 800,
      courtTypes: ['Tennis', 'Padel'],
      isAvailable: true,
      description:
          'Premium outdoor tennis courts with floodlights for night play. Hard-court surface maintained to international standards.',
      amenities: [
        'Parking',
        'Coaching Available',
        'Equipment Rental',
        'Night Lights',
      ],
      openTime: '05:30 AM',
      closeTime: '10:00 PM',
      distanceKm: 3.5,
      teamSize: 'Singles',
    ),
    Court(
      id: '4',
      stadiumId: 'std-002',
      stadiumName: 'Powai Racket Arena',
      name: 'Court B - Padel Club',
      place: 'Powai Lake Area',
      city: 'Powai',
      imageUrl:
          'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=800&q=80',
      rating: 4.4,
      reviewCount: 132,
      pricePerHour: 900,
      courtTypes: ['Padel'],
      isAvailable: true,
      description:
          'Modern padel court with anti-slip surface, perimeter glass, and dedicated evening lighting.',
      amenities: ['Parking', 'Coaching Available', 'Equipment Rental'],
      openTime: '06:00 AM',
      closeTime: '10:30 PM',
      distanceKm: 3.7,
      teamSize: '2v2',
    ),
    Court(
      id: '5',
      stadiumId: 'std-003',
      stadiumName: 'Bandra Multi-Sport Hub',
      name: 'Court X - Futsal 5s',
      place: 'Bandra Reclamation',
      city: 'Bandra West',
      imageUrl:
          'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?q=80&w=1470&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
      rating: 4.6,
      reviewCount: 312,
      pricePerHour: 1200,
      courtTypes: ['Futsal', 'Football'],
      isAvailable: false,
      description:
          'Indoor synthetic-turf futsal arena with 5-a-side and 7-a-side pitches. Fully air-conditioned with professional-grade goals.',
      amenities: [
        'Parking',
        'Changing Room',
        'Shower',
        'Canteen',
        'Scoreboard',
      ],
      openTime: '07:00 AM',
      closeTime: '11:00 PM',
      distanceKm: 5.1,
      teamSize: '5v5',
    ),
    Court(
      id: '6',
      stadiumId: 'std-003',
      stadiumName: 'Bandra Multi-Sport Hub',
      name: 'Court Y - Basketball Indoor',
      place: 'Bandra Reclamation',
      city: 'Bandra West',
      imageUrl:
          'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=800&q=80',
      rating: 4.3,
      reviewCount: 98,
      pricePerHour: 700,
      courtTypes: ['Basketball'],
      isAvailable: true,
      description:
          'Full-size NBA-standard indoor basketball courts. Hardwood flooring, professional ring height and backboards, with seating for spectators.',
      amenities: ['Parking', 'AC', 'Scoreboard', 'Spectator Seating'],
      openTime: '06:00 AM',
      closeTime: '10:00 PM',
      distanceKm: 7.8,
      teamSize: '5v5',
    ),
    Court(
      id: '7',
      stadiumId: 'std-004',
      stadiumName: 'Seaside Sports Club',
      name: 'Court C - Cricket Nets',
      place: 'Marine Drive Promenade',
      city: 'South Mumbai',
      imageUrl:
          'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=800&q=80',
      rating: 4.7,
      reviewCount: 221,
      pricePerHour: 950,
      courtTypes: ['Cricket'],
      isAvailable: true,
      description:
          'Professional cricket practice nets with turf pitch, bowling machine support, and evening flood lights.',
      amenities: ['Parking', 'Changing Room', 'Coaching Available', 'Nets'],
      openTime: '06:00 AM',
      closeTime: '10:00 PM',
      distanceKm: 4.2,
      teamSize: 'Practice Net',
    ),
    Court(
      id: '8',
      stadiumId: 'std-004',
      stadiumName: 'Seaside Sports Club',
      name: 'Court D - Aquatic Lanes',
      place: 'Marine Drive Promenade',
      city: 'South Mumbai',
      imageUrl:
          'https://images.unsplash.com/photo-1530549387789-4c1017266635?w=800&q=80',
      rating: 4.4,
      reviewCount: 88,
      pricePerHour: 500,
      courtTypes: ['Swimming'],
      isAvailable: true,
      description:
          'Lane-swim pool with dedicated timing slots, warm-up area, and family changing rooms.',
      amenities: ['Changing Room', 'Washroom', 'Parking', 'Drinking Water'],
      openTime: '05:00 AM',
      closeTime: '09:00 PM',
      distanceKm: 4.5,
      teamSize: 'Singles',
    ),
    Court(
      id: '9',
      stadiumId: 'std-004',
      stadiumName: 'Seaside Sports Club',
      name: 'Court E - Volleyball Arena',
      place: 'Marine Drive Promenade',
      city: 'South Mumbai',
      imageUrl:
          'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=800&q=80',
      rating: 4.5,
      reviewCount: 117,
      pricePerHour: 750,
      courtTypes: ['Volleyball'],
      isAvailable: true,
      description:
          'Indoor sand-free volleyball arena with tournament-grade net height and spectator seating.',
      amenities: ['Parking', 'Scoreboard', 'Spectator Seating', 'Lighting'],
      openTime: '06:00 AM',
      closeTime: '11:00 PM',
      distanceKm: 4.8,
      teamSize: '6v6',
    ),
  ];

  List<Court> getAllCourts() => List.unmodifiable(_courts);

  List<Stadium> getAllStadiums() => List.unmodifiable(_stadiums);

  Stadium? getStadiumById(String id) {
    for (final stadium in _stadiums) {
      if (stadium.id == id) return stadium;
    }
    return null;
  }

  List<Court> getCourtsByStadium(String stadiumId) {
    return _courts.where((court) => court.stadiumId == stadiumId).toList();
  }

  List<String> getAllCities() {
    final cities = _courts.map((c) => c.city).toSet().toList();
    cities.sort();
    return cities;
  }

  List<Court> filterByCities(List<String> cities) {
    if (cities.isEmpty) return getAllCourts();
    return _courts.where((c) => cities.contains(c.city)).toList();
  }

  List<Court> search(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return getAllCourts();
    return _courts
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.stadiumName.toLowerCase().contains(q) ||
              c.place.toLowerCase().contains(q) ||
              c.city.toLowerCase().contains(q) ||
              c.courtTypes.any((t) => t.toLowerCase().contains(q)),
        )
        .toList();
  }

  List<String> getAllSports() {
    final sports = <String>{};
    for (final court in _courts) {
      sports.addAll(court.courtTypes);
    }
    final list = sports.toList();
    list.sort();
    return list;
  }

  List<String> getAllTeamSizes() {
    final teamSizes = _courts.map((c) => c.teamSize).toSet().toList();
    teamSizes.sort();
    return teamSizes;
  }
}
