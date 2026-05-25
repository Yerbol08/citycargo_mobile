import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../providers/orders_provider.dart';

final publicOrderProvider = FutureProvider.family((ref, String number) {
  return ref.watch(ordersRepositoryProvider).getPublicOrder(number);
});

class PublicOrderScreen extends ConsumerWidget {
  final String orderNumber;
  const PublicOrderScreen({super.key, required this.orderNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(publicOrderProvider(orderNumber));
    return Scaffold(
      appBar: AppBar(title: const Text('Публичный заказ')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
          message: userErrorMessage(
            e,
            fallback: 'Не удалось открыть публичный заказ',
          ),
          onRetry: () => ref.invalidate(publicOrderProvider(orderNumber)),
        ),
        data: (order) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 0,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            order.number,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        AppBadge.orderStatus(order.status),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _Line('Откуда', order.senderAddress),
                    _Line('Куда', order.recipientAddress),
                    _Line('Цена', order.priceFormatted),
                    if (order.courierName != null)
                      _Line('Курьер', order.courierName!),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  final String value;
  const _Line(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          const Spacer(),
          Flexible(child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
