import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turf_booking/shared/models/user_model.dart';
import 'package:turf_booking/shared/repositories/auth_repository.dart';
import 'package:turf_booking/shared/exceptions/app_exceptions.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;

  SupabaseAuthRepository(this._client);

  @override
  Future<void> signUpWithEmail({
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
        throw Exception('Sign up failed - no user returned');
      }

      // create the auth user, then ensure the app stays logged out.
      if (response.session != null) {
        await _client.auth.signOut();
      }
    } on AuthException catch (e) {
      throw AppAuthException(e.message, e.statusCode, e);
    } catch (e) {
      throw UnknownException('Sign up failed: ${e.toString()}', e);
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
        throw Exception('Sign in failed - no user returned');
      }

      return _waitForUserProfile(response.user!.id);
    } on AuthException catch (e) {
      throw AppAuthException(e.message, e.statusCode, e);
    } catch (e) {
      throw UnknownException('Sign in failed: ${e.toString()}', e);
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.turfbooking://login-callback',
    );

    throw UnimplementedError(
      'Google sign in completes via authStateChanges stream',
    );
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw AppAuthException(e.message, e.statusCode, e);
    } catch (e) {
      throw UnknownException('Sign out failed: ${e.toString()}', e);
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    return _waitForUserProfile(user.id);
  }

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<UserModel> _fetchUserProfile(String userId) async {
    final data = await _client.from('users').select().eq('id', userId).single();

    return UserModel.fromJson(data);
  }

  Future<UserModel> _waitForUserProfile(String userId) async {
    for (int i = 0; i < 15; i++) {
      try {
        return await _fetchUserProfile(userId);
      } catch (_) {
        await Future.delayed(const Duration(milliseconds: 250));
      }
    }
    throw Exception('User profile not created in time');
  }
}
