import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

abstract class AuthRepository {
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  });

  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> signInWithGoogle();

  Future<void> signOut();

  Future<UserModel?> getCurrentUser();

  Stream<AuthState> get authStateChanges;
}
