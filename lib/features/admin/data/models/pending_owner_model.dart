class PendingOwnerModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String stadiumName;
  final String city;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime submittedAt;

  PendingOwnerModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.stadiumName,
    required this.city,
    required this.status,
    required this.submittedAt,
  });

  factory PendingOwnerModel.fromMap(String id, Map<String, dynamic> map) {
    return PendingOwnerModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      stadiumName: map['stadiumName'] ?? '',
      city: map['city'] ?? '',
      status: map['status'] ?? 'pending',
      submittedAt: DateTime.parse(map['submittedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}