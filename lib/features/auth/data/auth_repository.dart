import '../../../core/storage/token_storage.dart';
import '../data/auth_remote_datasource.dart';
import '../domain/models/auth_response_model.dart';
import '../domain/models/user_model.dart';

class AuthRepository {
  final AuthRemoteDataSource _remote;
  final TokenStorage _storage;

  AuthRepository(this._remote, this._storage);

  Future<AuthResponseModel> login(String phone, String password) async {
    final result = await _remote.login(phone, password);
    await _storage.saveTokens(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    );
    await _storage.saveUser(result.user.toJson());
    return result;
  }

  Future<void> logout() async {
    try {
      await _remote.logout();
    } catch (_) {}
    await _storage.clearAll();
  }

  Future<UserModel> getMe() async {
    try {
      final user = await _remote.getMe();
      await _storage.saveUser(user.toJson());
      return user;
    } catch (_) {
      final cached = await _storage.getUser();
      if (cached != null) return UserModel.fromJson(cached);
      rethrow;
    }
  }

  Future<bool> isAuthenticated() async {
    final token = await _storage.getAccessToken();
    return token != null;
  }
}
