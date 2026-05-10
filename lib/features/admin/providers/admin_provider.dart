import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/owner_application_model.dart';
import '../data/repositories/supabase_admin_repository.dart';

// Repository provider
final adminRepositoryProvider = Provider((ref) {
  return SupabaseAdminRepository();
});

// Pending applications provider
final pendingApplicationsProvider = FutureProvider<List<OwnerApplicationModel>>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  return repo.getPendingApplications();
});

// All users provider
final allUsersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  return repo.getAllUsers();
});

// All venues provider
final allVenuesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  return repo.getAllVenues();
});

// Dashboard stats provider
final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  return repo.getDashboardStats();
});

final allBookingsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  return repo.getAllBookings();
});