import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turf_booking/shared/models/user_model.dart';
import 'package:turf_booking/shared/repositories/auth_repository.dart';
import 'package:turf_booking/features/auth/data/supabase_auth_repository.dart';

part 'auth_provider.g.dart';

@riverpod
SupabaseClient supabaseClient(Ref ref) {
  return Supabase.instance.client;
}

@riverpod
AuthRepository authRepository(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseAuthRepository(client);
}

@riverpod
Stream<UserModel?> authState(Ref ref) async* {
  final repository = ref.watch(authRepositoryProvider);

  // Emit initial state
  final currentUser = await repository.getCurrentUser();
  yield currentUser;

  // Listen to auth changes
  await for (final state in repository.authStateChanges) {
    if (state.session == null) {
      yield null;
    } else {
      try {
        final user = await repository.getCurrentUser();
        yield user;
      } catch (_) {
        yield null;
      }
    }
  }
}
