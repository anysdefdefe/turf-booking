import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turf_booking/shared/models/user_model.dart';
import 'package:turf_booking/shared/repositories/auth_repository.dart';
import 'package:turf_booking/features/auth/data/supabase_auth_repository.dart';

part 'auth_providers.g.dart';

@riverpod
SupabaseClient supabaseClient(Ref ref) => Supabase.instance.client;

@riverpod
AuthRepository authRepository(Ref ref) {
  return SupabaseAuthRepository(ref.watch(supabaseClientProvider));
}

// THIS is your single source of truth. The router will watch this.
@riverpod
Stream<UserModel?> authState(Ref ref) async* {
  final repo = ref.watch(authRepositoryProvider);
  final supabase = ref.watch(supabaseClientProvider);

  await for (final authState in supabase.auth.onAuthStateChange) {
    if (authState.session == null) {
      yield null; // User logged out
    } else {
      try {
        // Fetch the custom UserModel from your database
        yield await repo.getCurrentUser();
      } catch (_) {
        yield null; // Error fetching profile
      }
    }
  }
}
