import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../shared/models/order_status.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../providers/orders_provider.dart';

final orderSecurityCodesProvider =
    FutureProvider.family<Map<String, dynamic>, String>(
  (ref, orderNumber) async {
    final order = await ref.watch(orderDetailProvider(orderNumber).future);
    return ref.watch(ordersRepositoryProvider).getSecurityCodes(order.id);
  },
);

class OrderSecurityCodesScreen extends ConsumerWidget {
  final String orderNumber;
  const OrderSecurityCodesScreen({super.key, required this.orderNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(orderSecurityCodesProvider(orderNumber));
    final orderAsync = ref.watch(orderDetailProvider(orderNumber));
    final status = orderAsync.maybeWhen(
      data: (order) => order.status,
      orElse: () => '',
    );
    final canShowPickup = OrderStatusMapper.canShowPickupCode(status);
    final canShowDelivery = OrderStatusMapper.canShowDeliveryCode(status);

    return Scaffold(
      appBar: AppBar(title: const Text('Коды заказа')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
          message: userErrorMessage(
            e,
            fallback: 'Не удалось загрузить коды заказа',
          ),
          onRetry: () =>
              ref.invalidate(orderSecurityCodesProvider(orderNumber)),
        ),
        data: (codes) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _CodeTile(
              title: 'Код забора',
              code: canShowPickup
                  ? (codes['pickup_code'] ?? codes['pickupCode'] ?? '----')
                      .toString()
                  : '----',
              note: canShowPickup
                  ? null
                  : 'Появится после прибытия курьера к отправителю.',
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            _CodeTile(
              title: 'Код доставки',
              code: canShowDelivery
                  ? (codes['delivery_code'] ?? codes['deliveryCode'] ?? '----')
                      .toString()
                  : '----',
              note: canShowDelivery
                  ? null
                  : 'Появится после забора заказа у отправителя.',
              color: AppColors.success,
            ),
          ],
        ),
      ),
    );
  }
}

class _CodeTile extends StatelessWidget {
  final String title;
  final String code;
  final String? note;
  final Color color;
  const _CodeTile({
    required this.title,
    required this.code,
    required this.color,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: color)),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                code,
                style: TextStyle(
                  color: color,
                  fontSize: 34,
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (note != null) ...[
              const SizedBox(height: 10),
              Text(
                note!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
