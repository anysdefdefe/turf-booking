import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:turf_booking/shared/models/user_model.dart';
import 'package:turf_booking/shared/repositories/auth_repository.dart';
import 'auth_provider.dart';

part 'auth_notifier.g.dart';

//state
class AuthState {
  final bool isLoading;
  final String? error;
  final UserModel? user;

  const AuthState({this.isLoading = false, this.error, this.user});

  AuthState copyWith({bool? isLoading, String? error, UserModel? user}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
    );
  }
}

//notifier
@riverpod
class AuthNotifier extends _$AuthNotifier {
  late final AuthRepository _repo;

  @override
  AuthState build() {
    _repo = ref.watch(authRepositoryProvider);
    return const AuthState();
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _repo.signInWithEmail(
        email: email,
        password: password,
      );

      state = state.copyWith(isLoading: false, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _repo.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
      );

      state = state.copyWith(isLoading: false, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signOut() async {
    try {
      await _repo.signOut();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
