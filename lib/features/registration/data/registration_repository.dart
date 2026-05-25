import '../../../core/api/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../features/auth/domain/models/auth_response_model.dart';
import '../domain/models/registration_model.dart';

class RegistrationRepository {
  final ApiClient _client;
  final TokenStorage _storage;

  RegistrationRepository(this._client, this._storage);

  Future<AuthResponseModel> registerClient(
      ClientRegistrationModel model) async {
    final endpoint = switch (model.role) {
      'sender' => '/api/v1/senders/register',
      'recipient' => '/api/v1/recipients/register',
      _ => '/api/v1/customers/register',
    };
    final data = await _client.post(endpoint, data: model.toJson());
    final result = AuthResponseModel.fromJson(data);
    await _storage.saveTokens(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    );
    await _storage.saveUser(result.user.toJson());
    return result;
  }

  Future<Map<String, dynamic>> registerCourier(
      CourierRegistrationModel model) async {
    return _client.post('/api/v1/couriers/register', data: model.toJson());
  }
}
