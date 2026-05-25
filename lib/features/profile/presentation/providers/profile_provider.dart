import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../features/auth/data/auth_repository.dart';
import '../../../../features/auth/domain/models/user_model.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class ProfileState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const ProfileState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  ProfileState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
  }) =>
      ProfileState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
      );
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final AuthRepository _authRepo;

  ProfileNotifier(this._authRepo) : super(const ProfileState());

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _authRepo.getMe();
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: userErrorMessage(
          e,
          fallback: 'Не удалось загрузить профиль',
        ),
      );
    }
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier(ref.watch(authRepositoryProvider));
});
