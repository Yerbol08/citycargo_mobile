import 'package:flutter/material.dart';

import '../../app/theme.dart';

enum OrderStatusGroup {
  created,
  assigned,
  inProgress,
  completed,
  cancelled,
  unknown,
}

class OrderStatusInfo {
  final String code;
  final String serverCode;
  final String label;
  final OrderStatusGroup group;
  final int timelineIndex;
  final Color backgroundColor;
  final Color textColor;

  const OrderStatusInfo({
    required this.code,
    required this.serverCode,
    required this.label,
    required this.group,
    required this.timelineIndex,
    required this.backgroundColor,
    required this.textColor,
  });

  bool get isActive =>
      group == OrderStatusGroup.created ||
      group == OrderStatusGroup.assigned ||
      group == OrderStatusGroup.inProgress;
}

class OrderStatusMapper {
  const OrderStatusMapper._();

  static OrderStatusInfo info(String rawStatus) {
    final code = normalize(rawStatus);
    return switch (code) {
      'created' => const OrderStatusInfo(
          code: 'created',
          serverCode: 'created',
          label: 'Новый',
          group: OrderStatusGroup.created,
          timelineIndex: 0,
          backgroundColor: AppColors.infoLight,
          textColor: AppColors.info,
        ),
      'assigned_to_courier' => const OrderStatusInfo(
          code: 'assigned_to_courier',
          serverCode: 'assigned_to_courier',
          label: 'Курьер назначен',
          group: OrderStatusGroup.assigned,
          timelineIndex: 1,
          backgroundColor: AppColors.primaryLight,
          textColor: AppColors.primary,
        ),
      'courier_arrived_sender' => const OrderStatusInfo(
          code: 'courier_arrived_sender',
          serverCode: 'courier_arrived_sender',
          label: 'Курьер прибыл к отправителю',
          group: OrderStatusGroup.inProgress,
          timelineIndex: 2,
          backgroundColor: AppColors.courierLight,
          textColor: AppColors.courier,
        ),
      'in_progress' => const OrderStatusInfo(
          code: 'in_progress',
          serverCode: 'in_progress',
          label: 'В работе',
          group: OrderStatusGroup.inProgress,
          timelineIndex: 2,
          backgroundColor: AppColors.primaryLight,
          textColor: AppColors.primary,
        ),
      'picked_up' => const OrderStatusInfo(
          code: 'picked_up',
          serverCode: 'picked_up',
          label: 'Забран у отправителя',
          group: OrderStatusGroup.inProgress,
          timelineIndex: 3,
          backgroundColor: AppColors.courierLight,
          textColor: AppColors.courier,
        ),
      'courier_arrived_recipient' => const OrderStatusInfo(
          code: 'courier_arrived_recipient',
          serverCode: 'courier_arrived_recipient',
          label: 'Курьер прибыл к получателю',
          group: OrderStatusGroup.inProgress,
          timelineIndex: 4,
          backgroundColor: AppColors.courierLight,
          textColor: AppColors.courier,
        ),
      'delivery_in_progress' => const OrderStatusInfo(
          code: 'delivery_in_progress',
          serverCode: 'delivery_in_progress',
          label: 'В доставке',
          group: OrderStatusGroup.inProgress,
          timelineIndex: 4,
          backgroundColor: AppColors.courierLight,
          textColor: AppColors.courier,
        ),
      'delivered' => const OrderStatusInfo(
          code: 'delivered',
          serverCode: 'delivered',
          label: 'Доставлен',
          group: OrderStatusGroup.completed,
          timelineIndex: 5,
          backgroundColor: AppColors.successLight,
          textColor: AppColors.success,
        ),
      'completed' => const OrderStatusInfo(
          code: 'completed',
          serverCode: 'completed',
          label: 'Доставлен',
          group: OrderStatusGroup.completed,
          timelineIndex: 5,
          backgroundColor: AppColors.successLight,
          textColor: AppColors.success,
        ),
      'cancelled' => const OrderStatusInfo(
          code: 'cancelled',
          serverCode: 'cancelled',
          label: 'Отменен',
          group: OrderStatusGroup.cancelled,
          timelineIndex: 5,
          backgroundColor: AppColors.dangerLight,
          textColor: AppColors.danger,
        ),
      _ => OrderStatusInfo(
          code: code,
          serverCode: code,
          label: code.isEmpty ? 'Без статуса' : code,
          group: OrderStatusGroup.unknown,
          timelineIndex: 0,
          backgroundColor: AppColors.grayBg,
          textColor: AppColors.textSecondary,
        ),
    };
  }

  static String normalize(String rawStatus) {
    final value = rawStatus.trim();
    return switch (value) {
      'courier_assigned' => 'assigned_to_courier',
      'courier_arrived_sender' ||
      'courier_arrived_at_sender' ||
      'arrived_at_sender' ||
      'arrived_to_sender' ||
      'arrived_sender' =>
        'courier_arrived_sender',
      'pickup_in_progress' => 'in_progress',
      'picked_up_from_sender' ||
      'picked_up_at_sender' ||
      'pickup_confirmed' ||
      'collected' =>
        'picked_up',
      'courier_arrived_recipient' ||
      'courier_arrived_at_recipient' ||
      'arrived_at_recipient' ||
      'arrived_to_recipient' ||
      'arrived_recipient' =>
        'courier_arrived_recipient',
      'canceled' => 'cancelled',
      _ => value,
    };
  }

  static bool isCreated(String status) =>
      info(status).group == OrderStatusGroup.created;
  static bool isAssigned(String status) =>
      info(status).group == OrderStatusGroup.assigned;
  static bool isInProgress(String status) =>
      info(status).group == OrderStatusGroup.inProgress;
  static bool isCompleted(String status) =>
      info(status).group == OrderStatusGroup.completed;
  static bool isCancelled(String status) =>
      info(status).group == OrderStatusGroup.cancelled;

  static bool belongsToCourier(String status) =>
      isAssigned(status) || isInProgress(status) || isCompleted(status);

  static bool canShowPickupCode(String status) {
    final code = normalize(status);
    return const {
      'courier_arrived_sender',
      'in_progress',
      'picked_up',
      'courier_arrived_recipient',
      'delivery_in_progress',
      'delivered',
      'completed',
    }.contains(code);
  }

  static bool canShowDeliveryCode(String status) {
    final code = normalize(status);
    return const {
      'picked_up',
      'courier_arrived_recipient',
      'delivery_in_progress',
      'delivered',
      'completed',
    }.contains(code);
  }
}
