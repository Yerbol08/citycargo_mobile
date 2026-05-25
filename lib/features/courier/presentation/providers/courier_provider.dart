import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/courier_repository.dart';
import '../../domain/models/courier_model.dart';

final courierRepositoryProvider = Provider<CourierRepository>((ref) {
  return CourierRepository(ref.watch(apiClientProvider));
});

class CourierState {
  final CourierModel? profile;
  final bool isOnline;
  final bool isLoading;
  final String? error;

  const CourierState({
    this.profile,
    this.isOnline = false,
    this.isLoading = false,
    this.error,
  });

  CourierState copyWith({
    CourierModel? profile,
    bool? isOnline,
    bool? isLoading,
    String? error,
  }) =>
      CourierState(
        profile: profile ?? this.profile,
        isOnline: isOnline ?? this.isOnline,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
      );
}

class CourierNotifier extends StateNotifier<CourierState> {
  final CourierRepository _repo;

  CourierNotifier(this._repo) : super(const CourierState());

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true);
    try {
      final profile = await _repo.getCourierProfile();
      state = state.copyWith(profile: profile, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: userErrorMessage(
          e,
          fallback: 'Не удалось загрузить профиль курьера',
        ),
      );
    }
  }

  Future<void> toggleOnline(bool value) async {
    state = state.copyWith(isOnline: value);
    try {
      await _repo.updateOnlineStatus(value);
    } catch (_) {
      // Revert on failure
      state = state.copyWith(isOnline: !value);
    }
  }
}

final courierProvider =
    StateNotifierProvider<CourierNotifier, CourierState>((ref) {
  return CourierNotifier(ref.watch(courierRepositoryProvider));
});
