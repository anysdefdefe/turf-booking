class AdminStatsModel {
  final int totalStadiums;
  final int totalBookings;
  final double totalRevenue;
  final double commissionEarned;
  final int pendingApprovals;

  AdminStatsModel({
    required this.totalStadiums,
    required this.totalBookings,
    required this.totalRevenue,
    required this.commissionEarned,
    required this.pendingApprovals,
  });

  factory AdminStatsModel.fromMap(Map<String, dynamic> map) {
    return AdminStatsModel(
      totalStadiums: map['totalStadiums'] ?? 0,
      totalBookings: map['totalBookings'] ?? 0,
      totalRevenue: (map['totalRevenue'] ?? 0).toDouble(),
      commissionEarned: (map['commissionEarned'] ?? 0).toDouble(),
      pendingApprovals: map['pendingApprovals'] ?? 0,
    );
  }
}