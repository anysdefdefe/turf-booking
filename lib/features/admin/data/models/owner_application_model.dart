class OwnerApplicationModel {
  final String id;
  final String userId;
  final String businessName;
  final String phone;
  final String message;
  final String status;
  final DateTime createdAt;
  final String? documentUrl;

  // From users table (joined)
  final String? ownerName;
  final String? ownerEmail;

  OwnerApplicationModel({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.phone,
    required this.message,
    required this.status,
    required this.createdAt,
    this.documentUrl,
    this.ownerName,
    this.ownerEmail,
  });

  factory OwnerApplicationModel.fromMap(Map<String, dynamic> map) {
    return OwnerApplicationModel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      businessName: map['business_name'] ?? '',
      phone: map['phone'] ?? '',
      message: map['message'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: DateTime.parse(map['created_at']),
      documentUrl: map['document_url'],
      // from joined users table
      ownerName: map['users']?['full_name'],
      ownerEmail: map['users']?['email'],
    );
  }
}