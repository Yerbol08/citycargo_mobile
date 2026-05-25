import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../features/orders/presentation/providers/orders_provider.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/security_code_input.dart';

class CourierSecurityCodeInputScreen extends ConsumerWidget {
  final String orderNumber;
  final bool isPickup;

  const CourierSecurityCodeInputScreen({
    super.key,
    required this.orderNumber,
    required this.isPickup,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(ordersRepositoryProvider);
    final orderAsync = ref.watch(orderDetailProvider(orderNumber));
    final color = isPickup ? AppColors.courierLight : AppColors.successLight;
    final instrColor = isPickup ? AppColors.courier : AppColors.success;
    final title = isPickup ? 'Забрать посылку' : 'Подтвердить доставку';
    final instruction = isPickup
        ? 'Подтвердите прибытие к отправителю и попросите код забора.'
        : 'Попросите получателя показать код доставки из приложения.';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPickup
                          ? Icons.inventory_2_outlined
                          : Icons.check_circle_outline,
                      color: instrColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        instruction,
                        style: TextStyle(
                          color: instrColor,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              orderAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => AppErrorWidget(
                  message: userErrorMessage(
                    e,
                    fallback: 'Не удалось открыть заказ',
                  ),
                  onRetry: () =>
                      ref.invalidate(orderDetailProvider(orderNumber)),
                ),
                data: (order) => SecurityCodeInput(
                  type: isPickup ? CodeType.pickup : CodeType.delivery,
                  onSubmit: (code) async {
                    if (isPickup) {
                      await repo.confirmPickup(order.id, code);
                    } else {
                      await repo.confirmDelivery(order.id, code);
                    }
                    ref.invalidate(orderDetailProvider(orderNumber));
                    ref
                        .read(courierArrivalStepProvider(orderNumber).notifier)
                        .state = CourierArrivalStep.none;
                    await ref
                        .read(courierOrdersProvider.notifier)
                        .load(refresh: true);
                    if (context.mounted) _showSuccessAndPop(context, isPickup);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessAndPop(BuildContext context, bool isPickup) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        icon:
            const Icon(Icons.check_circle, color: AppColors.success, size: 56),
        title: Text(
          isPickup ? 'Посылка получена' : 'Доставка подтверждена',
          textAlign: TextAlign.center,
        ),
        content: Text(
          isPickup
              ? 'Теперь доставьте посылку получателю.'
              : 'Заказ успешно завершен.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
