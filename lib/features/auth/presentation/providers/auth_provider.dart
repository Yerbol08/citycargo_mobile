import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_role.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/auth_remote_datasource.dart';
import '../../data/auth_repository.dart';
import '../../domain/models/user_model.dart';
import '../../../../core/services/sync_queue_service.dart';

// Incremented when server returns 401 and refresh fails; breaks the circular dependency with apiClientProvider.
final _sessionKillProvider = StateProvider<int>((ref) => 0);

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final client = ApiClient(
    tokenStorage: storage,
    onUnauthorized: () {
      storage.deleteTokens();
      ref.read(_sessionKillProvider.notifier).update((s) => s + 1);
    },
    onForbidden: (_) {},
  );
  
  return client;
});

final syncQueueServiceProvider = Provider<SyncQueueService>((ref) {
  final client = ref.watch(apiClientProvider);
  return client.syncQueue;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  final storage = ref.watch(tokenStorageProvider);
  final remote = AuthRemoteDataSource(client);
  return AuthRepository(remote, storage);
});

class AuthState {
  final UserModel? user;
  final AppRole? activeRole;
  final bool isLoading;
  final bool isInitializing;
  final String? error;

  const AuthState({
    this.user,
    this.activeRole,
    this.isLoading = false,
    this.isInitializing = false,
    this.error,
  });

  bool get isAuthenticated => user != null;
  List<AppRole> get availableRoles => user?.roles ?? const [];
  bool get needsRoleSelection => isAuthenticated && activeRole == null;

  AuthState copyWith({
    UserModel? user,
    AppRole? activeRole,
    bool? isLoading,
    bool? isInitializing,
    String? error,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      activeRole: clearUser ? null : (activeRole ?? this.activeRole),
      isLoading: isLoading ?? this.isLoading,
      isInitializing: isInitializing ?? this.isInitializing,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  final TokenStorage _storage;

  AuthNotifier(this._repo, this._storage)
      : super(const AuthState(isInitializing: true)) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final token = await _storage.getAccessToken();
      final userData = await _storage.getUser();
      if (token != null && userData != null && mounted) {
        final user = UserModel.fromJson(userData);
        final storedRole = AppRole.fromCode(await _storage.getActiveRole());
        state = AuthState(
          user: user,
          activeRole: _validRoleOrDefault(user, storedRole),
        );
        return;
      }
    } catch (_) {}
    if (mounted) state = const AuthState();
  }

  void clearSession() {
    state = const AuthState();
  }

  Future<void> login(String phone, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repo.login(phone, password);
      final role =
          result.user.roles.length == 1 ? result.user.roles.first : null;
      if (role != null) await _storage.saveActiveRole(role.code);
      state = state.copyWith(
        user: result.user,
        activeRole: role,
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.userMessage);
      rethrow;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Не удалось войти. Проверьте данные и попробуйте снова',
      );
      rethrow;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState();
  }

  Future<void> setActiveRole(AppRole role) async {
    final user = state.user;
    if (user == null || !user.roles.contains(role)) return;
    await _storage.saveActiveRole(role.code);
    state = state.copyWith(activeRole: role);
  }

  Future<void> loadCurrentUser() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repo.getMe();
      state = state.copyWith(
        user: user,
        activeRole: _validRoleOrDefault(user, state.activeRole),
        isLoading: false,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('loadCurrentUser failed: $e');
      state = state.copyWith(
        isLoading: false,
        error:
            e is ApiException ? e.userMessage : 'Не удалось обновить профиль',
      );
    }
  }
}

AppRole? _validRoleOrDefault(UserModel user, AppRole? role) {
  if (role != null && user.roles.contains(role)) return role;
  return user.roles.length == 1 ? user.roles.first : null;
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final notifier = AuthNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(tokenStorageProvider),
  );
  ref.listen<int>(_sessionKillProvider, (_, __) {
    notifier.clearSession();
  });
  return notifier;
});
