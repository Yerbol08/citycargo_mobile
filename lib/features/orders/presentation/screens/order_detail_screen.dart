import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/order_status.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/order_detail_tools.dart';
import '../providers/orders_provider.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderNumber;
  const OrderDetailScreen({super.key, required this.orderNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(orderDetailProvider(orderNumber));
    return async.when(
      loading: () => const Scaffold(
        body:
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: AppErrorWidget(
          message: userErrorMessage(
            e,
            fallback: 'Не удалось открыть заказ',
          ),
          onRetry: () => ref.refresh(orderDetailProvider(orderNumber)),
        ),
      ),
      data: (order) {
        final encodedNumber = Uri.encodeComponent(order.number);
        final encodedId = Uri.encodeComponent(order.id);
        final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
        final pickupCode = OrderStatusMapper.canShowPickupCode(order.status)
            ? order.pickupCode
            : null;
        final deliveryCode = OrderStatusMapper.canShowDeliveryCode(order.status)
            ? order.deliveryCode
            : null;
        return Scaffold(
          appBar: AppBar(
              title: const Text(
                  '\u0414\u0435\u0442\u0430\u043b\u0438 \u0437\u0430\u043a\u0430\u0437\u0430')),
          body: ListView(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 32 + bottomInset),
            children: [
              _HeroCard(
                number: order.number,
                status: order.status,
                price: order.priceFormatted,
              ),
              const SizedBox(height: 12),
              _RouteCard(
                senderAddress: order.senderAddress,
                senderPhone: order.senderPhone,
                recipientAddress: order.recipientAddress,
                recipientPhone: order.recipientPhone,
              ),
              const SizedBox(height: 12),
              _ActionGrid(
                actions: [
                  _ActionSpec(
                    icon: Icons.chat_outlined,
                    label: '\u0427\u0430\u0442',
                    onTap: () => context.push(
                      '/chat/$encodedId?title=${Uri.encodeComponent(order.number)}',
                    ),
                  ),
                  _ActionSpec(
                    icon: Icons.history,
                    label: '\u0418\u0441\u0442\u043e\u0440\u0438\u044f',
                    onTap: () => context.push('/orders/$encodedNumber/history'),
                  ),
                  _ActionSpec(
                    icon: Icons.pin_outlined,
                    label: '\u041a\u043e\u0434\u044b',
                    onTap: () =>
                        context.push('/orders/$encodedNumber/security-codes'),
                  ),
                  _ActionSpec(
                    icon: Icons.public,
                    label: '\u041f\u0443\u0431\u043b\u0438\u0447\u043d\u043e',
                    onTap: () => context.push('/orders/$encodedNumber/public'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OrderMiniMapCard(order: order),
              const SizedBox(height: 12),
              OrderTimelineCard(status: order.status),
              const SizedBox(height: 12),
              _DetailsCard(
                parcelCount: order.parcelCount,
                courierName: order.courierName,
                courierReward: order.courierRewardMinor > 0
                    ? order.courierRewardFormatted
                    : null,
                systemCommission: order.systemCommissionMinor > 0
                    ? order.systemCommissionFormatted
                    : null,
                financialHoldStatus: order.financialHoldStatus,
                courierPayoutStatus: order.courierPayoutStatus,
                createdAt: order.createdAt == null
                    ? null
                    : DateFormatter.formatDateTime(order.createdAt!),
                comment: order.comment,
              ),
              if (pickupCode != null || deliveryCode != null) ...[
                const SizedBox(height: 12),
                _CodesPreview(
                  pickupCode: pickupCode,
                  deliveryCode: deliveryCode,
                  encodedNumber: encodedNumber,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String number;
  final String status;
  final String price;
  const _HeroCard({
    required this.number,
    required this.status,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: number.isEmpty ? 'order-$hashCode' : 'order-$number',
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  number,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              AppBadge.orderStatus(status),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            '\u0421\u0442\u043e\u0438\u043c\u043e\u0441\u0442\u044c \u0437\u0430\u043a\u0430\u0437\u0430',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final String senderAddress;
  final String senderPhone;
  final String recipientAddress;
  final String recipientPhone;

  const _RouteCard({
    required this.senderAddress,
    required this.senderPhone,
    required this.recipientAddress,
    required this.recipientPhone,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '\u041c\u0430\u0440\u0448\u0440\u0443\u0442',
      child: IntrinsicHeight(
        child: Row(
          children: [
            Column(
              children: [
                _RouteDot(color: AppColors.primary),
                Expanded(
                  child: Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    color: AppColors.border,
                  ),
                ),
                _RouteDot(color: AppColors.success),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  _AddressBlock(
                    label: '\u041e\u0442\u043a\u0443\u0434\u0430',
                    address: senderAddress,
                    phone: senderPhone,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 18),
                  _AddressBlock(
                    label: '\u041a\u0443\u0434\u0430',
                    address: recipientAddress,
                    phone: recipientPhone,
                    color: AppColors.success,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressBlock extends StatelessWidget {
  final String label;
  final String address;
  final String phone;
  final Color color;

  const _AddressBlock({
    required this.label,
    required this.address,
    required this.phone,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                address.isEmpty
                    ? '\u0410\u0434\u0440\u0435\u0441 \u043d\u0435 \u0443\u043a\u0430\u0437\u0430\u043d'
                    : address,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 3),
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
        IconButton.filledTonal(
          onPressed:
              phone.isEmpty ? null : () => launchUrl(Uri.parse('tel:$phone')),
          icon: const Icon(Icons.phone_outlined, size: 18),
          color: color,
          style: IconButton.styleFrom(
            backgroundColor: color.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }
}

class _ActionGrid extends StatelessWidget {
  final List<_ActionSpec> actions;
  const _ActionGrid({required this.actions});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.92,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        return Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          child: InkWell(
            onTap: action.onTap,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(action.icon, color: AppColors.primary, size: 22),
                  const SizedBox(height: 8),
                  Text(
                    action.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ActionSpec {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionSpec({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class _DetailsCard extends StatelessWidget {
  final int parcelCount;
  final String? courierName;
  final String? courierReward;
  final String? systemCommission;
  final String? financialHoldStatus;
  final String? courierPayoutStatus;
  final String? createdAt;
  final String? comment;

  const _DetailsCard({
    required this.parcelCount,
    this.courierName,
    this.courierReward,
    this.systemCommission,
    this.financialHoldStatus,
    this.courierPayoutStatus,
    this.createdAt,
    this.comment,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '\u0418\u043d\u0444\u043e\u0440\u043c\u0430\u0446\u0438\u044f',
      child: Column(
        children: [
          _InfoRow('\u041c\u0435\u0441\u0442', '$parcelCount'),
          if (courierName != null && courierName!.isNotEmpty)
            _InfoRow('\u041a\u0443\u0440\u044c\u0435\u0440', courierName!),
          if (courierReward != null)
            _InfoRow(
                '\u0412\u043e\u0437\u043d\u0430\u0433\u0440\u0430\u0436\u0434\u0435\u043d\u0438\u0435 \u043a\u0443\u0440\u044c\u0435\u0440\u0430',
                courierReward!),
          if (systemCommission != null)
            _InfoRow(
                '\u041a\u043e\u043c\u0438\u0441\u0441\u0438\u044f \u0441\u0435\u0440\u0432\u0438\u0441\u0430',
                systemCommission!),
          if (financialHoldStatus != null && financialHoldStatus!.isNotEmpty)
            _InfoRow('\u041e\u043f\u043b\u0430\u0442\u0430',
                _financialHoldLabel(financialHoldStatus!)),
          if (courierPayoutStatus != null && courierPayoutStatus!.isNotEmpty)
            _InfoRow(
                '\u0412\u044b\u043f\u043b\u0430\u0442\u0430 \u043a\u0443\u0440\u044c\u0435\u0440\u0443',
                _payoutLabel(courierPayoutStatus!)),
          if (createdAt != null)
            _InfoRow('\u0421\u043e\u0437\u0434\u0430\u043d', createdAt!),
          if (comment != null && comment!.isNotEmpty)
            _InfoRow(
                '\u041a\u043e\u043c\u043c\u0435\u043d\u0442\u0430\u0440\u0438\u0439',
                comment!),
        ],
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

class _CodesPreview extends StatelessWidget {
  final String? pickupCode;
  final String? deliveryCode;
  final String encodedNumber;
  const _CodesPreview({
    required this.pickupCode,
    required this.deliveryCode,
    required this.encodedNumber,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '\u041a\u043e\u0434\u044b',
      child: Column(
        children: [
          if (pickupCode != null)
            _CodeRow(
              label: '\u0417\u0430\u0431\u043e\u0440',
              code: pickupCode!,
              onTap: () => context.push('/orders/$encodedNumber/pickup-code'),
            ),
          if (pickupCode != null && deliveryCode != null)
            const Divider(height: 20),
          if (deliveryCode != null)
            _CodeRow(
              label: '\u0414\u043e\u0441\u0442\u0430\u0432\u043a\u0430',
              code: deliveryCode!,
              onTap: () => context.push('/orders/$encodedNumber/delivery-code'),
            ),
        ],
      ),
    );
  }
}

class _CodeRow extends StatelessWidget {
  final String label;
  final String code;
  final VoidCallback onTap;
  const _CodeRow({
    required this.label,
    required this.code,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary)),
            const Spacer(),
            Text(
              code,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.grayText),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteDot extends StatelessWidget {
  final Color color;
  const _RouteDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 11,
      height: 11,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
