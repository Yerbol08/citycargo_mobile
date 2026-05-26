import 'package:flutter_test/flutter_test.dart';
import 'package:citycargo_mobile/shared/models/order_status.dart';

void main() {
  group('OrderStatusMapper', () {
    test('normalize should correctly map backend aliases to standard codes', () {
      expect(OrderStatusMapper.normalize('courier_assigned'), 'assigned_to_courier');
      expect(OrderStatusMapper.normalize('arrived_at_sender'), 'courier_arrived_sender');
      expect(OrderStatusMapper.normalize('collected'), 'picked_up');
      expect(OrderStatusMapper.normalize('arrived_to_recipient'), 'courier_arrived_recipient');
      expect(OrderStatusMapper.normalize('canceled'), 'cancelled');
      
      // Should not change already standard codes
      expect(OrderStatusMapper.normalize('assigned_to_courier'), 'assigned_to_courier');
      expect(OrderStatusMapper.normalize('picked_up'), 'picked_up');
    });

    test('info should return correct OrderStatusInfo', () {
      final created = OrderStatusMapper.info('created');
      expect(created.code, 'created');
      expect(created.group, OrderStatusGroup.created);

      final pickedUp = OrderStatusMapper.info('picked_up_from_sender'); // Using alias
      expect(pickedUp.code, 'picked_up');
      expect(pickedUp.group, OrderStatusGroup.inProgress);
    });

    test('isCompleted should return true only for completed/delivered statuses', () {
      expect(OrderStatusMapper.isCompleted('completed'), isTrue);
      expect(OrderStatusMapper.isCompleted('delivered'), isTrue);
      
      expect(OrderStatusMapper.isCompleted('created'), isFalse);
      expect(OrderStatusMapper.isCompleted('picked_up'), isFalse);
    });

    test('canShowDeliveryCode should return true for picked_up and beyond', () {
      expect(OrderStatusMapper.canShowDeliveryCode('picked_up'), isTrue);
      expect(OrderStatusMapper.canShowDeliveryCode('courier_arrived_recipient'), isTrue);
      expect(OrderStatusMapper.canShowDeliveryCode('delivered'), isTrue);

      expect(OrderStatusMapper.canShowDeliveryCode('created'), isFalse);
      expect(OrderStatusMapper.canShowDeliveryCode('courier_arrived_sender'), isFalse);
    });
  });
}
