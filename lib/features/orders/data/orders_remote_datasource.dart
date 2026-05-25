import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/utils/api_helpers.dart';
import '../../../shared/models/api_response_model.dart';
import '../../../shared/models/order_status.dart';
import '../domain/models/order_model.dart';

class OrdersRemoteDataSource {
  final ApiClient _client;

  OrdersRemoteDataSource(this._client);

  Future<List<OrderSummary>> getOrders({
    String? status,
    String? role,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (status != null) params['status_code'] = status;
    if (role != null) params['actor_role'] = role;
    final data = await _client.get('/api/v1/orders', params: params);
    debugPrint('ORDERS RESPONSE: $data');
    final list = extractList(data['data'] ?? data);
    return list.map((e) => OrderSummary.fromJson(extractMap(e))).toList();
  }

  Future<List<OrderSummary>> getCourierOrders({String? courierId}) async {
    final statuses = const [
      'created',
      'assigned_to_courier',
      'courier_assigned',
      'arrived_at_sender',
      'courier_arrived_at_sender',
      'in_progress',
      'pickup_in_progress',
      'picked_up',
      'picked_up_from_sender',
      'delivery_in_progress',
      'delivered',
      'completed',
    ];
    final byId = <String, OrderSummary>{};

    for (final status in statuses) {
      final Map<String, dynamic> data;
      try {
        data = await _client.get(
          '/api/v1/orders',
          params: {'page': 1, 'limit': 100, 'status_code': status},
        );
      } on ApiException catch (error) {
        if (kDebugMode) {
          debugPrint('Courier orders status "$status" skipped: ${error.code}');
        }
        continue;
      }
      final list = extractList(data['data'] ?? data)
          .map((e) => OrderSummary.fromJson(extractMap(e)))
          .where((order) {
        final statusInfo = OrderStatusMapper.info(order.status);
        if (statusInfo.group == OrderStatusGroup.created) return true;
        return OrderStatusMapper.belongsToCourier(order.status);
      });

      for (final order in list) {
        final key = order.id.isNotEmpty ? order.id : order.number;
        if (key.isNotEmpty) byId[key] = order;
      }
    }

    return byId.values.toList();
  }

  Future<List<OrderSummary>> getCourierAvailableOrders({String? phone}) async {
    final params = <String, dynamic>{
      'page': 1,
      'limit': 20,
      'status_code': 'created',
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
    };
    final data = await _client.get('/api/v1/orders', params: params);
    final list = extractList(data['data'] ?? data);
    return list.map((e) => OrderSummary.fromJson(extractMap(e))).toList();
  }

  Future<OrderModel> getOrderByNumber(String number) async {
    final orderNumber = number.trim();
    debugPrint('GETTING ORDER BY NUMBER: $orderNumber');
    if (orderNumber.isEmpty) {
      throw const ApiException(
        code: 'INVALID_ID',
        message: 'Номер заказа некорректен',
      );
    }

    final encodedNumber = Uri.encodeComponent(orderNumber);
    final data = await _client.get('/api/v1/orders/number/$encodedNumber');
    debugPrint('ORDER DETAIL DATA: $data');
    final raw = data['data'];
    if (raw == null) {
      throw const ApiException(
        code: 'EMPTY_RESPONSE',
        message: 'Сервер вернул пустой ответ',
      );
    }
    return OrderModel.fromJson(extractMap(raw));
  }

  Future<Map<String, dynamic>> getSecurityCodes(String orderId) async {
    final encodedId = Uri.encodeComponent(orderId);
    final data = await _client.get('/api/v1/orders/$encodedId/security-codes');
    return extractMap(data['data'] ?? data);
  }

  Future<OrderModel> getPublicOrder(String orderNumber) async {
    final encodedNumber = Uri.encodeComponent(orderNumber.trim());
    final data = await _client.get('/api/v1/public/orders/$encodedNumber');
    return OrderModel.fromJson(extractMap(data['data'] ?? data));
  }

  Future<List<Map<String, dynamic>>> getOrderHistory(String orderNumber) async {
    final encodedNumber = Uri.encodeComponent(orderNumber.trim());
    final data = await _client
        .get('/api/v1/moderator/orders/number/$encodedNumber/history');
    return extractList(data['data'] ?? data).map((e) => extractMap(e)).toList();
  }

  Future<OrderModel> createOrder(Map<String, dynamic> body) async {
    final data = await _client.post('/api/v1/orders', data: body);
    return OrderModel.fromJson(extractMap(data['data'] ?? data));
  }

  Future<OrderModel> changeStatus(
    String orderId,
    String status, {
    String? reason,
  }) async {
    final encodedId = Uri.encodeComponent(orderId);
    final data = await _client.post(
      '/api/v1/orders/$encodedId/change-status',
      data: {
        'status_code': status,
        if (reason != null) 'reason': reason,
      },
    );
    return OrderModel.fromJson(extractMap(data['data'] ?? data));
  }

  Future<void> confirmPickup(String orderId, String code) async {
    final encodedId = Uri.encodeComponent(orderId);
    await _client.post(
      '/api/v1/orders/$encodedId/confirm-pickup',
      data: {'code': code},
    );
  }

  Future<void> confirmDelivery(String orderId, String code) async {
    final encodedId = Uri.encodeComponent(orderId);
    await _client.post(
      '/api/v1/orders/$encodedId/confirm-delivery',
      data: {'code': code},
    );
  }

  Future<void> regenerateCode(String orderId) async {
    final encodedId = Uri.encodeComponent(orderId);
    await _client.post('/api/v1/orders/$encodedId/security-codes/regenerate');
  }
}
