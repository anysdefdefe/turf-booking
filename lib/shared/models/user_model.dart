class UserModel {
  final String id;
  final String email;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;
  final bool isOwner;
  final bool isApproved;
  final bool isAdmin;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    this.avatarUrl,
    this.isOwner = false,
    this.isApproved = false,
    this.isAdmin = false,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isOwner: json['is_owner'] as bool? ?? false,
      isApproved: json['is_approved'] as bool? ?? false,
      isAdmin: json['is_admin'] as bool? ?? false,
      createdAt: json['created_at'] is String
          ? DateTime.parse(json['created_at'])
          : json['created_at'] as DateTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'avatar_url': avatarUrl,
      'is_owner': isOwner,
      'is_approved': isApproved,
      'is_admin': isAdmin,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isOwnerApproved => isOwner && isApproved;
}
