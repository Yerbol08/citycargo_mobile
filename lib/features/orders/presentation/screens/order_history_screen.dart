import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/order_status.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../providers/orders_provider.dart';

final orderHistoryProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, number) {
  return ref.watch(ordersRepositoryProvider).getOrderHistory(number);
});

class OrderHistoryScreen extends ConsumerWidget {
  final String orderNumber;
  const OrderHistoryScreen({super.key, required this.orderNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(orderHistoryProvider(orderNumber));
    return Scaffold(
      appBar: AppBar(title: const Text('История заказа')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
          message: userErrorMessage(
            e,
            fallback: 'Не удалось загрузить историю заказа',
          ),
          onRetry: () => ref.invalidate(orderHistoryProvider(orderNumber)),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'История пока пустая',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              final code = (item['status_code'] ??
                      item['to_status_code'] ??
                      item['status'] ??
                      item['event'] ??
                      '')
                  .toString();
              final title =
                  code.isEmpty ? 'Событие' : OrderStatusMapper.info(code).label;
              final reason =
                  (item['reason'] ?? item['comment'] ?? '').toString().trim();
              final rawDate =
                  (item['created_at'] ?? item['createdAt'])?.toString();
              final date = rawDate == null ? null : DateTime.tryParse(rawDate);
              return Card(
                elevation: 0,
                color: Colors.white,
                child: ListTile(
                  leading: const Icon(Icons.history, color: AppColors.primary),
                  title: Text(title),
                  subtitle: Text([
                    if (reason.isNotEmpty) reason,
                    if (date != null) DateFormatter.formatDateTime(date),
                  ].join('\n')),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
