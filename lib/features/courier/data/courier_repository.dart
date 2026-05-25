import '../../../core/api/api_client.dart';
import '../domain/models/courier_model.dart';

class CourierRepository {
  final ApiClient _client;

  CourierRepository(this._client);

  Future<CourierModel> getCourierProfile() async {
    final data = await _client.get('/api/v1/me');
    return CourierModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> updateOnlineStatus(bool isOnline) async {
    await _client.post(
      '/api/v1/me/courier/status',
      data: {'is_online': isOnline},
    );
  }
}
