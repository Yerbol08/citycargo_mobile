import 'package:flutter_test/flutter_test.dart';
import 'package:citycargo_mobile/features/orders/domain/models/order_model.dart';

void main() {
  group('OrderModel.fromJson', () {
    test('should parse correctly with standard fields', () {
      final json = {
        'id': '123',
        'order_number': 'ORD-001',
        'status': 'created',
        'sender_phone': '+77011111111',
        'sender_address': 'Address 1',
        'sender_lat': 43.1,
        'sender_lng': 76.1,
        'recipient_phone': '+77022222222',
        'recipient_address': 'Address 2',
        'recipient_lat': 43.2,
        'recipient_lng': 76.2,
        'parcel_count': 2,
        'price_minor': 1000,
        'currency': 'KZT',
        'created_at': '2024-05-19T10:00:00Z',
      };

      final order = OrderModel.fromJson(json);

      expect(order.id, '123');
      expect(order.number, 'ORD-001');
      expect(order.parcelCount, 2);
      expect(order.priceMinor, 1000);
      expect(order.createdAt, isA<DateTime>());
    });

    test('should handle alternative ID fields (order_id, pk)', () {
      final json1 = {'order_id': '456'};
      final json2 = {'pk': '789'};
      final json3 = {'orderId': 'abc'};

      expect(OrderModel.fromJson(json1).id, '456');
      expect(OrderModel.fromJson(json2).id, '789');
      expect(OrderModel.fromJson(json3).id, 'abc');
    });

    test('should handle alternative status and number fields', () {
      final json = {
        'status_code': 'accepted',
        'number': 'N-001',
      };

      final order = OrderModel.fromJson(json);
      expect(order.status, 'accepted');
      expect(order.number, 'N-001');
    });

    test('should handle nested courier info', () {
      final json = {
        'courier_info': {
          'first_name': 'Ivan',
          'last_name': 'Ivanov',
        }
      };

      final order = OrderModel.fromJson(json);
      expect(order.courierName, 'Ivan Ivanov');
    });

    test('should fallback for courier name if first/last missing', () {
      final json = {
        'courier_info': {
          'name': 'Simple Name',
        }
      };

      final order = OrderModel.fromJson(json);
      expect(order.courierName, 'Simple Name');
    });
  });
}
