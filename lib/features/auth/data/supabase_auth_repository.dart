import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turf_booking/shared/models/user_model.dart';
import 'package:turf_booking/shared/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;

  SupabaseAuthRepository(this._client);

  @override
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      if (response.user == null) {
        throw Exception('Sign up failed — no user returned');
      }

      return _waitForUserProfile(response.user!.id);
    } catch (e) {
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Sign in failed — no user returned');
      }

      return _fetchUserProfile(response.user!.id);
    } catch (e) {
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.turfbooking://login-callback',
    );

    // OAuth completes via authStateChanges stream
    throw UnimplementedError(
      'Google sign in completes via authStateChanges stream',
    );
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    return _fetchUserProfile(user.id);
  }

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // 🔒 Private helpers

  Future<UserModel> _fetchUserProfile(String userId) async {
    final data = await _client.from('users').select().eq('id', userId).single();

    return UserModel.fromJson(data);
  }

  Future<UserModel> _waitForUserProfile(String userId) async {
    for (int i = 0; i < 5; i++) {
      try {
        return await _fetchUserProfile(userId);
      } catch (_) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
    throw Exception('User profile not created in time');
  }
}
