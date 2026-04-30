import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/owner_application_model.dart';
import 'admin_repository.dart';

class SupabaseAdminRepository implements AdminRepository {
  final _supabase = Supabase.instance.client;

  // ─── APPROVALS ───────────────────────────────────────────

  @override
  Future<List<OwnerApplicationModel>> getPendingApplications() async {
    final response = await _supabase
        .from('owner_applications')
        .select('*, users(full_name, email)')
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (response as List)
        .map((map) => OwnerApplicationModel.fromMap(map))
        .toList();
  }

  @override
  Future<void> approveOwner(String applicationId, String userId) async {
    // Update application status
    await _supabase
        .from('owner_applications')
        .update({'status': 'approved'})
        .eq('id', applicationId);

    // Update user to be approved owner
    await _supabase
        .from('users')
        .update({'is_owner': true, 'is_approved': true})
        .eq('id', userId);
  }

  @override
  Future<void> rejectOwner(
    String applicationId,
    String userId,
    String reason,
  ) async {
    // Update application status
    await _supabase
        .from('owner_applications')
        .update({'status': 'rejected'})
        .eq('id', applicationId);

    // Update user
    await _supabase
        .from('users')
        .update({'is_owner': false, 'is_approved': false})
        .eq('id', userId);
  }

  // ─── USERS ───────────────────────────────────────────────

  @override
  @override
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final currentUserId = _supabase.auth.currentUser!.id;

    print('🔍 Current admin ID: $currentUserId');

    final response = await _supabase
        .from('users')
        .select()
        .neq('id', currentUserId)
        .order('created_at', ascending: false);

    print('👥 Users fetched: ${response.length}');
    print('👥 Users data: $response');

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<void> blockUser(String userId) async {
    await _supabase.from('users').update({'is_blocked': true}).eq('id', userId);
  }

  @override
  Future<void> unblockUser(String userId) async {
    await _supabase
        .from('users')
        .update({'is_blocked': false})
        .eq('id', userId);
  }

  // ─── VENUES ──────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getAllVenues() async {
    final response = await _supabase
        .from('stadiums')
        .select()
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<void> suspendVenue(String venueId) async {
    await _supabase
        .from('stadiums')
        .update({'is_active': false})
        .eq('id', venueId);
  }

  @override
  Future<void> activateVenue(String venueId) async {
    await _supabase
        .from('stadiums')
        .update({'is_active': true})
        .eq('id', venueId);
  }

  // ---------------------------- BOOKINGS------------------------------------
  @override
  Future<List<Map<String, dynamic>>> getAllBookings() async {
    final response = await _supabase
        .from('bookings')
        .select('*, users!customer_id(full_name, email), slots(*)')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // ─── DASHBOARD ───────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> getDashboardStats() async {
    final users = await _supabase.from('users').select().eq('is_admin', false);

    final stadiums = await _supabase.from('stadiums').select();

    final bookings = await _supabase.from('bookings').select();

    final pending = await _supabase
        .from('owner_applications')
        .select()
        .eq('status', 'pending');

    double totalRevenue = 0;
    for (var booking in bookings) {
      totalRevenue += (booking['total_amount'] ?? 0).toDouble();
    }

    return {
      'totalUsers': (users as List).length,
      'totalVenues': (stadiums as List).length,
      'totalBookings': (bookings as List).length,
      'totalRevenue': totalRevenue,
      'pendingApprovals': (pending as List).length,
    };
  }
}
