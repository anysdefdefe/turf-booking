import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: dotenv.env['OAUTH_REDIRECT_URL'],
      );
    } on AuthException catch (e) {
      throw AppAuthException(e.message, e.statusCode, e);
    } catch (e) {
      throw UnknownException('Google sign in failed: ${e.toString()}', e);
    }
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
    try {
      final data = await _client.from('users').select().eq('id', userId).single();
      return UserModel.fromJson(data);
    } catch (e) {
      if (e is PostgrestException && e.code == 'PGRST116') {
        final user = _client.auth.currentUser;
        if (user != null && user.id == userId) {
          final metadata = user.userMetadata ?? {};
          final fullName = metadata['full_name'] ?? metadata['name'] ?? user.email?.split('@').first ?? 'User';
          
          try {
            final insertData = await _client.from('users').insert({
              'id': userId,
              'email': user.email ?? '',
              'full_name': fullName,
            }).select().single();
            return UserModel.fromJson(insertData);
          } catch (insertError) {
            print('Auto-insert fallback failed: $insertError');
          }
        }
      }
      rethrow;
    }
  }

  Future<UserModel> _waitForUserProfile(String userId) async {
    Object? lastError;
    for (int i = 0; i < 30; i++) {
      try {
        return await _fetchUserProfile(userId);
      } catch (e) {
        lastError = e;
        print('AUTH POLL [$i]: Failed to fetch profile for $userId — $e');
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    print('AUTH FATAL: All 30 retries exhausted. Last error: $lastError');
    throw Exception('User profile not created in time');
  }
}
