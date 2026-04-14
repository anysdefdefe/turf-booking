import '../models/admin_stats_model.dart';
import '../models/pending_owner_model.dart';

class AdminRepository {
  AdminRepository._();
  static final AdminRepository instance = AdminRepository._();

  // Dummy stats
  Future<AdminStatsModel> getAdminStats() async {
    return AdminStatsModel(
      totalStadiums: 6,
      totalBookings: 124,
      totalRevenue: 62000,
      commissionEarned: 6200,
      pendingApprovals: 3,
    );
  }

  // Dummy pending owners
  Future<List<PendingOwnerModel>> getPendingOwners() async {
    return [
      PendingOwnerModel(
        id: '1',
        name: 'Rahul Sharma',
        email: 'rahul@gmail.com',
        phone: '9876543210',
        stadiumName: 'Rahul Badminton Arena',
        city: 'Bengaluru',
        status: 'pending',
        submittedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      PendingOwnerModel(
        id: '2',
        name: 'Priya Nair',
        email: 'priya@gmail.com',
        phone: '9123456780',
        stadiumName: 'Priya Futsal Zone',
        city: 'Mumbai',
        status: 'pending',
        submittedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      PendingOwnerModel(
        id: '3',
        name: 'Arjun Patel',
        email: 'arjun@gmail.com',
        phone: '9988776655',
        stadiumName: 'Arjun Cricket Hub',
        city: 'Pune',
        status: 'pending',
        submittedAt: DateTime.now(),
      ),
    ];
  }

  // Dummy users
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    return [
      {'id': '1', 'name': 'Amit Kumar', 'email': 'amit@gmail.com', 'blocked': false},
      {'id': '2', 'name': 'Sneha Reddy', 'email': 'sneha@gmail.com', 'blocked': false},
      {'id': '3', 'name': 'Vikram Singh', 'email': 'vikram@gmail.com', 'blocked': true},
    ];
  }

  // Dummy venues
  Future<List<Map<String, dynamic>>> getAllVenues() async {
    return [
      {'id': '1', 'name': 'Arena Pro Badminton', 'city': 'Andheri West', 'suspended': false},
      {'id': '2', 'name': 'Smash Zone', 'city': 'Powai', 'suspended': false},
      {'id': '3', 'name': 'Kick & Play Futsal', 'city': 'Goregaon East', 'suspended': true},
      {'id': '4', 'name': 'Court Kings Basketball', 'city': 'Bandra West', 'suspended': false},
    ];
  }

  // These will connect to Firebase later
  Future<void> approveOwner(String id) async {}
  Future<void> rejectOwner(String id, String reason) async {}
  Future<void> blockUser(String userId) async {}
  Future<void> unblockUser(String userId) async {}
  Future<void> suspendVenue(String venueId) async {}
}