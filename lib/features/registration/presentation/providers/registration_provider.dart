import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/registration_repository.dart';
import '../../domain/models/registration_model.dart';

final registrationRepositoryProvider = Provider<RegistrationRepository>((ref) {
  return RegistrationRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  );
});

class RegistrationState {
  final bool isLoading;
  final String? error;

  const RegistrationState({this.isLoading = false, this.error});

  RegistrationState copyWith({bool? isLoading, String? error}) =>
      RegistrationState(isLoading: isLoading ?? this.isLoading, error: error);
}

class RegistrationNotifier extends StateNotifier<RegistrationState> {
  final RegistrationRepository _repo;

  RegistrationNotifier(this._repo) : super(const RegistrationState());

  Future<void> registerClient(ClientRegistrationModel model) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.registerClient(model);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: userErrorMessage(
          e,
          fallback: 'Не удалось зарегистрировать клиента',
        ),
      );
      rethrow;
    }
  }

  Future<void> registerCourier(CourierRegistrationModel model) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.registerCourier(model);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: userErrorMessage(
          e,
          fallback: 'Не удалось отправить заявку курьера',
        ),
      );
      rethrow;
    }
  }
}

final registrationProvider =
    StateNotifierProvider<RegistrationNotifier, RegistrationState>((ref) {
  return RegistrationNotifier(ref.watch(registrationRepositoryProvider));
});
