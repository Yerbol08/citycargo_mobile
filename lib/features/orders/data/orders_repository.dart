import '../../../core/services/sync_queue_service.dart';
import '../data/orders_remote_datasource.dart';
import '../domain/models/order_model.dart';
import '../../../shared/models/api_response_model.dart';
import '../../../core/api/api_exception.dart';

class OrdersRepository {
  final OrdersRemoteDataSource _remote;
  final SyncQueueService? _syncQueue;

  OrdersRepository(this._remote, {SyncQueueService? syncQueue}) : _syncQueue = syncQueue;

  Future<List<OrderSummary>> getOrders({
    String? status,
    String? role,
    int page = 1,
    int limit = 20,
  }) =>
      _remote.getOrders(status: status, role: role, page: page, limit: limit);

  Future<List<OrderSummary>> getCourierAvailableOrders({String? phone}) =>
      _remote.getCourierAvailableOrders(phone: phone);

  Future<List<OrderSummary>> getCourierOrders({String? courierId}) =>
      _remote.getCourierOrders(courierId: courierId);

  Future<OrderModel> getOrder(String orderNumber) =>
      _remote.getOrderByNumber(orderNumber);

  Future<Map<String, dynamic>> getSecurityCodes(String orderId) =>
      _remote.getSecurityCodes(orderId);

  Future<OrderModel> getPublicOrder(String orderNumber) =>
      _remote.getPublicOrder(orderNumber);

  Future<List<Map<String, dynamic>>> getOrderHistory(String orderNumber) =>
      _remote.getOrderHistory(orderNumber);

  Future<OrderModel> createOrder({
    required String senderPhone,
    required String senderAddress,
    required double senderLat,
    required double senderLng,
    required String recipientPhone,
    required String recipientAddress,
    required double recipientLat,
    required double recipientLng,
    required int parcelCount,
    String? comment,
  }) {
    return _remote.createOrder({
      'sender_phone': senderPhone,
      'sender_address': senderAddress,
      'sender_lat': senderLat,
      'sender_lng': senderLng,
      'recipient_phone': recipientPhone,
      'recipient_address': recipientAddress,
      'recipient_lat': recipientLat,
      'recipient_lng': recipientLng,
      'parcel_count': parcelCount,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });
  }

  Future<OrderModel> changeStatus(String orderId, String status,
          {String? reason}) async {
    try {
      return await _remote.changeStatus(orderId, status, reason: reason);
    } on ApiException catch (e) {
      if (e.code == 'NO_INTERNET' && _syncQueue != null) {
        final encodedId = Uri.encodeComponent(orderId);
        await _syncQueue!.enqueue(
          'POST',
          '/api/v1/orders/$encodedId/change-status',
          data: {
            'status_code': status,
            if (reason != null) 'reason': reason,
          },
        );
        // Return a mock OrderModel for optimistic UI
        return OrderModel(
          id: orderId,
          number: 'Офлайн (в очереди)',
          status: status,
          senderPhone: '',
          senderAddress: '',
          senderLat: 0,
          senderLng: 0,
          recipientPhone: '',
          recipientAddress: '',
          recipientLat: 0,
          recipientLng: 0,
          parcelCount: 1,
          priceMinor: 0,
          systemCommissionMinor: 0,
          courierRewardMinor: 0,
          currency: 'KZT',
        );
      }
      rethrow;
    }
  }

  Future<void> confirmPickup(String orderId, String code) async {
    try {
      await _remote.confirmPickup(orderId, code);
    } on ApiException catch (e) {
      if (e.code == 'NO_INTERNET' && _syncQueue != null) {
        final encodedId = Uri.encodeComponent(orderId);
        await _syncQueue!.enqueue(
          'POST',
          '/api/v1/orders/$encodedId/confirm-pickup',
          data: {'code': code},
        );
        return;
      }
      rethrow;
    }
  }

  Future<void> confirmDelivery(String orderId, String code) async {
    try {
      await _remote.confirmDelivery(orderId, code);
    } on ApiException catch (e) {
      if (e.code == 'NO_INTERNET' && _syncQueue != null) {
        final encodedId = Uri.encodeComponent(orderId);
        await _syncQueue!.enqueue(
          'POST',
          '/api/v1/orders/$encodedId/confirm-delivery',
          data: {'code': code},
        );
        return;
      }
      rethrow;
    }
  }

  Future<void> regenerateCode(String orderId) =>
      _remote.regenerateCode(orderId);
}
