import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../shared/models/order_status.dart';
import '../../../../shared/widgets/app_button.dart';
import '../providers/orders_provider.dart';

class SecurityCodeDisplayScreen extends ConsumerStatefulWidget {
  final String orderNumber;
  final bool isPickup;

  const SecurityCodeDisplayScreen({
    super.key,
    required this.orderNumber,
    required this.isPickup,
  });

  @override
  ConsumerState<SecurityCodeDisplayScreen> createState() =>
      _SecurityCodeDisplayScreenState();
}

class _SecurityCodeDisplayScreenState
    extends ConsumerState<SecurityCodeDisplayScreen> {
  Timer? _timer;
  int _secondsLeft = 1800;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timerText {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _regenerate() async {
    try {
      final order =
          await ref.read(orderDetailProvider(widget.orderNumber).future);
      await ref.read(ordersRepositoryProvider).regenerateCode(order.id);
      ref.invalidate(orderDetailProvider(widget.orderNumber));
      setState(() => _secondsLeft = 1800);
      _startTimer();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userErrorMessage(
            e,
            fallback: 'Не удалось обновить код',
          )),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(orderDetailProvider(widget.orderNumber));
    final isPickup = widget.isPickup;

    final color = isPickup ? AppColors.primary : AppColors.success;
    final bgColor = isPickup ? AppColors.primaryLight : AppColors.successLight;
    final title = isPickup ? 'Код забора' : 'Код доставки';
    final instruction = isPickup
        ? 'Покажите этот код курьеру при передаче посылки'
        : 'Покажите этот код курьеру при получении посылки';

    final code = async.maybeWhen(
      data: (order) {
        final canShow = isPickup
            ? OrderStatusMapper.canShowPickupCode(order.status)
            : OrderStatusMapper.canShowDeliveryCode(order.status);
        if (!canShow) return '----';
        return isPickup
            ? (order.pickupCode ?? '----')
            : (order.deliveryCode ?? '----');
      },
      orElse: () => '....',
    );

    final blockedText = async.maybeWhen(
      data: (order) {
        final canShow = isPickup
            ? OrderStatusMapper.canShowPickupCode(order.status)
            : OrderStatusMapper.canShowDeliveryCode(order.status);
        if (canShow) return null;
        return isPickup
            ? 'Код появится после того, как курьер подтвердит прибытие к отправителю.'
            : 'Код доставки появится после забора заказа у отправителя.';
      },
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.horizontalPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        code,
                        style: TextStyle(
                          color: color,
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          color: color.withValues(alpha: 0.7),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Действителен: $_timerText',
                          style: TextStyle(
                            color: color.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                blockedText ?? instruction,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),
              if (isPickup)
                AppButton(
                  label: 'Обновить код',
                  onPressed: blockedText == null ? _regenerate : null,
                  outlined: true,
                  icon: Icons.refresh,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
