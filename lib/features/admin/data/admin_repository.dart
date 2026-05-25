import '../../../core/api/api_client.dart';
import '../../../core/utils/api_helpers.dart';
import '../../../shared/models/api_response_model.dart';

class AdminRepository {
  final ApiClient _client;

  AdminRepository(this._client);

  Future<List<Map<String, dynamic>>> getUsers() async {
    final data = await _client.get('/api/v1/users');
    return extractList(data['data'] ?? data).map(extractMap).toList();
  }

  Future<Map<String, dynamic>> getUserDetails(String userId) async {
    final data = await _client.get(
      '/api/v1/moderator/users/${Uri.encodeComponent(userId)}',
    );
    return extractMap(data['data'] ?? data);
  }

  Future<void> updateUser(String userId, Map<String, dynamic> body) async {
    await _client.patch(
      '/api/v1/users/${Uri.encodeComponent(userId)}',
      data: body,
    );
  }

  Future<List<OrderSummary>> getOrders({
    String? status,
    String? phone,
  }) async {
    final params = <String, dynamic>{'page': 1, 'limit': 50};
    if (status != null && status.isNotEmpty) params['status_code'] = status;
    if (phone != null && phone.isNotEmpty) params['phone'] = phone;
    final data = await _client.get('/api/v1/orders', params: params);
    return extractList(data['data'] ?? data)
        .map((e) => OrderSummary.fromJson(extractMap(e)))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getOrderHistory(String orderNumber) async {
    final encoded = Uri.encodeComponent(orderNumber.trim());
    final data =
        await _client.get('/api/v1/moderator/orders/number/$encoded/history');
    return extractList(data['data'] ?? data).map(extractMap).toList();
  }

  Future<List<Map<String, dynamic>>> getOrderStatuses() async {
    final data = await _client.get('/api/v1/order-statuses');
    return extractList(data['data'] ?? data).map(extractMap).toList();
  }

  Future<void> assignCourier({
    required String orderId,
    required String courierId,
    String? vehicleId,
  }) async {
    await _client.post(
      '/api/v1/orders/${Uri.encodeComponent(orderId)}/assign-courier',
      data: {
        'courier_id': courierId,
        if (vehicleId != null && vehicleId.isNotEmpty) 'vehicle_id': vehicleId,
      },
    );
  }

  Future<void> changeOrderStatus({
    required String orderId,
    required String status,
    String? reason,
  }) async {
    await _client.post(
      '/api/v1/orders/${Uri.encodeComponent(orderId)}/change-status',
      data: {
        'status_code': status,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
  }

  Future<Map<String, dynamic>> getSecurityCodes(String orderId) async {
    final data = await _client.get(
      '/api/v1/orders/${Uri.encodeComponent(orderId)}/security-codes',
    );
    return extractMap(data['data'] ?? data);
  }

  Future<List<Map<String, dynamic>>> getCouriers({String? status}) async {
    final data = await _client.get(
      '/api/v1/couriers',
      params: {
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    return extractList(data['data'] ?? data).map(extractMap).toList();
  }

  Future<List<Map<String, dynamic>>> getCourierHistory(String profileId) async {
    final data = await _client.get(
      '/api/v1/couriers/${Uri.encodeComponent(profileId)}/history',
    );
    return extractList(data['data'] ?? data).map(extractMap).toList();
  }

  Future<Map<String, dynamic>> getLocation(String userId) async {
    final data = await _client.get(
      '/api/v1/locations/${Uri.encodeComponent(userId)}',
    );
    return extractMap(data['data'] ?? data);
  }

  Future<void> approveCourier(String profileId, {String? comment}) async {
    await _client.post(
      '/api/v1/couriers/${Uri.encodeComponent(profileId)}/approve',
      data: {if (comment != null && comment.isNotEmpty) 'comment': comment},
    );
  }

  Future<void> rejectCourier(
    String profileId, {
    required String reason,
    String? comment,
  }) async {
    await _client.post(
      '/api/v1/couriers/${Uri.encodeComponent(profileId)}/reject',
      data: {
        'reason': reason,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getTopups({
    String? status,
    String? phone,
  }) async {
    final data = await _client.get(
      '/api/v1/topups',
      params: {
        'page': 1,
        'limit': 50,
        if (status != null && status.isNotEmpty) 'status': status,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );
    return extractList(data['data'] ?? data).map(extractMap).toList();
  }

  Future<Map<String, dynamic>> getTopup(String topupId) async {
    final data = await _client.get(
      '/api/v1/topups/${Uri.encodeComponent(topupId)}',
    );
    return extractMap(data['data'] ?? data);
  }

  Future<void> confirmTopup(String topupId) async {
    await _client
        .post('/api/v1/topups/${Uri.encodeComponent(topupId)}/confirm');
  }

  Future<void> rejectTopup(String topupId, String reason) async {
    await _client.post(
      '/api/v1/topups/${Uri.encodeComponent(topupId)}/reject',
      data: {'reason': reason},
    );
  }

  Future<Map<String, dynamic>> getPricing() async {
    final data = await _client.get('/api/v1/pricing/current');
    return extractMap(data['data'] ?? data);
  }

  Future<void> updatePricing(Map<String, dynamic> body) async {
    await _client.put('/api/v1/pricing/current', data: body);
  }

  Future<List<Map<String, dynamic>>> getCommissionReport() async {
    final data = await _client.get(
      '/api/v1/wallets/system/commission-report',
      params: {'page': 1, 'limit': 50},
    );
    return extractList(data['data'] ?? data).map(extractMap).toList();
  }
}
