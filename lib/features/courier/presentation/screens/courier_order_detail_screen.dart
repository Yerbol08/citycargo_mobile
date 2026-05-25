import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../features/orders/presentation/providers/orders_provider.dart';
import '../../../../shared/models/order_status.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/order_detail_tools.dart';

class CourierOrderDetailScreen extends ConsumerWidget {
  final String orderNumber;
  const CourierOrderDetailScreen({super.key, required this.orderNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(orderDetailProvider(orderNumber));
    return async.when(
      loading: () => const Scaffold(
        body:
            Center(child: CircularProgressIndicator(color: AppColors.courier)),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: AppErrorWidget(
          message: userErrorMessage(e,
              fallback:
                  '\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u043f\u043e\u0434\u0442\u0432\u0435\u0440\u0434\u0438\u0442\u044c \u043f\u0440\u0438\u0431\u044b\u0442\u0438\u0435'),
          onRetry: () => ref.refresh(orderDetailProvider(orderNumber)),
        ),
      ),
      data: (order) {
        String? ctaLabel;
        String? codeRoute;
        CourierArrivalStep? nextArrivalStep;
        final status = OrderStatusMapper.normalize(order.status);
        final arrivalStep = ref.watch(courierArrivalStepProvider(order.number));

        switch (status) {
          case 'assigned_to_courier':
            if (arrivalStep == CourierArrivalStep.arrivedAtSender) {
              ctaLabel =
                  '\u041f\u043e\u0434\u0442\u0432\u0435\u0440\u0434\u0438\u0442\u044c \u043a\u043e\u0434 \u0437\u0430\u0431\u043e\u0440\u0430';
              codeRoute =
                  '/courier/orders/${Uri.encodeComponent(order.number)}/pickup-code';
            } else {
              ctaLabel =
                  '\u041f\u0440\u0438\u0431\u044b\u043b \u043a \u043e\u0442\u043f\u0440\u0430\u0432\u0438\u0442\u0435\u043b\u044e';
              nextArrivalStep = CourierArrivalStep.arrivedAtSender;
            }
          case 'courier_arrived_sender':
          case 'in_progress':
            ctaLabel =
                '\u041f\u043e\u0434\u0442\u0432\u0435\u0440\u0434\u0438\u0442\u044c \u043a\u043e\u0434 \u0437\u0430\u0431\u043e\u0440\u0430';
            codeRoute =
                '/courier/orders/${Uri.encodeComponent(order.number)}/pickup-code';
          case 'picked_up':
            if (arrivalStep == CourierArrivalStep.arrivedAtRecipient) {
              ctaLabel =
                  '\u041f\u043e\u0434\u0442\u0432\u0435\u0440\u0434\u0438\u0442\u044c \u043a\u043e\u0434 \u0434\u043e\u0441\u0442\u0430\u0432\u043a\u0438';
              codeRoute =
                  '/courier/orders/${Uri.encodeComponent(order.number)}/delivery-code';
            } else {
              ctaLabel =
                  '\u041f\u0440\u0438\u0431\u044b\u043b \u043a \u043f\u043e\u043b\u0443\u0447\u0430\u0442\u0435\u043b\u044e';
              nextArrivalStep = CourierArrivalStep.arrivedAtRecipient;
            }
          case 'delivery_in_progress':
          case 'courier_arrived_recipient':
            ctaLabel =
                '\u041f\u043e\u0434\u0442\u0432\u0435\u0440\u0434\u0438\u0442\u044c \u043a\u043e\u0434 \u0434\u043e\u0441\u0442\u0430\u0432\u043a\u0438';
            codeRoute =
                '/courier/orders/${Uri.encodeComponent(order.number)}/delivery-code';
        }

        final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
        return Scaffold(
          appBar: AppBar(
            title: Text(order.number),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(child: AppBadge.orderStatus(order.status)),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSizes.horizontalPadding,
              AppSizes.horizontalPadding,
              AppSizes.horizontalPadding,
              104 + bottomInset,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AddressCard(
                  label: '\u041e\u0442\u043a\u0443\u0434\u0430',
                  address: order.senderAddress,
                  phone: order.senderPhone,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 12),
                _AddressCard(
                  label: '\u041a\u0443\u0434\u0430',
                  address: order.recipientAddress,
                  phone: order.recipientPhone,
                  color: AppColors.success,
                ),
                const SizedBox(height: 12),
                OrderMiniMapCard(order: order, interactive: true),
                const SizedBox(height: 12),
                OrderTimelineCard(status: order.status),
                const SizedBox(height: 12),
                OrderNavigationActions(order: order),
                const SizedBox(height: 12),
                _ParcelCard(order: order),
                if (ctaLabel != null) ...[
                  const SizedBox(height: 28),
                  AppButton(
                    label: ctaLabel,
                    color: AppColors.courier,
                    onPressed: () {
                      if (codeRoute != null) {
                        context.push(codeRoute);
                      } else if (nextArrivalStep != null) {
                        ref
                            .read(courierArrivalStepProvider(order.number)
                                .notifier)
                            .state = nextArrivalStep;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              nextArrivalStep ==
                                      CourierArrivalStep.arrivedAtSender
                                  ? '\u0422\u0435\u043f\u0435\u0440\u044c \u0432\u0432\u0435\u0434\u0438\u0442\u0435 \u043a\u043e\u0434 \u0437\u0430\u0431\u043e\u0440\u0430 \u043e\u0442 \u043e\u0442\u043f\u0440\u0430\u0432\u0438\u0442\u0435\u043b\u044f'
                                  : '\u0422\u0435\u043f\u0435\u0440\u044c \u0432\u0432\u0435\u0434\u0438\u0442\u0435 \u043a\u043e\u0434 \u0434\u043e\u0441\u0442\u0430\u0432\u043a\u0438 \u043e\u0442 \u043f\u043e\u043b\u0443\u0447\u0430\u0442\u0435\u043b\u044f',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            mini: true,
            backgroundColor: AppColors.primary,
            onPressed: () => context.push(
              '/chat/${Uri.encodeComponent(order.id)}'
              '?title=${Uri.encodeComponent(order.number)}',
            ),
            child: const Icon(Icons.chat_outlined),
          ),
        );
      },
    );
  }
}

class _AddressCard extends StatelessWidget {
  final String label;
  final String address;
  final String phone;
  final Color color;

  const _AddressCard({
    required this.label,
    required this.address,
    required this.phone,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    phone,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.phone_outlined, color: color),
              onPressed: () => launchUrl(Uri.parse('tel:$phone')),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParcelCard extends StatelessWidget {
  final dynamic order;
  const _ParcelCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '\u041f\u043e\u0441\u044b\u043b\u043a\u0430',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _Row('\u041c\u0435\u0441\u0442', '${order.parcelCount}'),
            _Row(
                '\u0426\u0435\u043d\u0430 \u0437\u0430\u043a\u0430\u0437\u0430',
                order.priceFormatted),
            if (order.courierName != null && order.courierName!.isNotEmpty)
              _Row('\u041a\u0443\u0440\u044c\u0435\u0440', order.courierName!),
            if (order.courierRewardMinor > 0)
              _RewardRow(
                  '\u0412\u043e\u0437\u043d\u0430\u0433\u0440\u0430\u0436\u0434\u0435\u043d\u0438\u0435',
                  order.courierRewardFormatted),
            if (order.systemCommissionMinor > 0)
              _Row(
                  '\u041a\u043e\u043c\u0438\u0441\u0441\u0438\u044f \u0441\u0435\u0440\u0432\u0438\u0441\u0430',
                  order.systemCommissionFormatted),
            if (order.financialHoldStatus != null &&
                order.financialHoldStatus!.isNotEmpty)
              _Row('\u041e\u043f\u043b\u0430\u0442\u0430',
                  _financialHoldLabel(order.financialHoldStatus!)),
            if (order.courierPayoutStatus != null &&
                order.courierPayoutStatus!.isNotEmpty)
              _Row(
                  '\u0412\u044b\u043f\u043b\u0430\u0442\u0430 \u043a\u0443\u0440\u044c\u0435\u0440\u0443',
                  _payoutLabel(order.courierPayoutStatus!)),
            if (order.createdAt != null)
              _Row('\u0421\u043e\u0437\u0434\u0430\u043d',
                  DateFormatter.formatDateTime(order.createdAt!)),
            if (order.comment != null && order.comment!.isNotEmpty)
              _Row(
                  '\u041a\u043e\u043c\u043c\u0435\u043d\u0442\u0430\u0440\u0438\u0439',
                  order.comment!),
          ],
        ),
      ),
    );
  }

  String _financialHoldLabel(String status) => switch (status) {
        'active' =>
          '\u0425\u043e\u043b\u0434 \u0430\u043a\u0442\u0438\u0432\u0435\u043d',
        'captured' =>
          '\u041e\u043f\u043b\u0430\u0442\u0430 \u0441\u043f\u0438\u0441\u0430\u043d\u0430',
        'released' => '\u0425\u043e\u043b\u0434 \u0441\u043d\u044f\u0442',
        'refunded' => '\u0412\u043e\u0437\u0432\u0440\u0430\u0442',
        _ => status,
      };

  String _payoutLabel(String status) => switch (status) {
        'not_paid' =>
          '\u041d\u0435 \u0432\u044b\u043f\u043b\u0430\u0447\u0435\u043d\u043e',
        'pending' =>
          '\u041e\u0436\u0438\u0434\u0430\u0435\u0442 \u0432\u044b\u043f\u043b\u0430\u0442\u044b',
        'paid' => '\u0412\u044b\u043f\u043b\u0430\u0447\u0435\u043d\u043e',
        'failed' =>
          '\u041e\u0448\u0438\u0431\u043a\u0430 \u0432\u044b\u043f\u043b\u0430\u0442\u044b',
        _ => status,
      };
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  final String label;
  final String value;
  const _RewardRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
