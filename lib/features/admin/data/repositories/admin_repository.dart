import '../models/owner_application_model.dart';

abstract class AdminRepository {
  // Approvals
  Future<List<OwnerApplicationModel>> getPendingApplications();
  Future<void> approveOwner(String applicationId, String userId);
  Future<void> rejectOwner(String applicationId, String userId, String reason);

  // Users
  Future<List<Map<String, dynamic>>> getAllUsers();
  Future<void> blockUser(String userId);
  Future<void> unblockUser(String userId);

  // Venues
  Future<List<Map<String, dynamic>>> getAllVenues();
  Future<void> suspendVenue(String venueId);
  Future<void> activateVenue(String venueId);

  // Dashboard
  Future<Map<String, dynamic>> getDashboardStats();
  // Bookings
  Future<List<Map<String, dynamic>>> getAllBookings();
  }