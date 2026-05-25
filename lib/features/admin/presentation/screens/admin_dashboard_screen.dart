import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../shared/models/api_response_model.dart';
import '../../../../shared/models/order_status.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_cards.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  final bool moderator;

  const AdminDashboardScreen({super.key, required this.moderator});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  late Future<_DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DashboardData> _load() async {
    final repo = ref.read(adminRepositoryProvider);
    final orders = await repo.getOrders();
    final pendingCouriers = await repo.getCouriers(status: 'pending');
    final pendingTopups = widget.moderator
        ? await repo.getTopups(status: 'pending')
        : <Map<String, dynamic>>[];

    return _DashboardData(
      newOrders:
          orders.where((o) => OrderStatusMapper.isCreated(o.status)).length,
      activeOrders:
          orders.where((o) => OrderStatusMapper.isInProgress(o.status)).length,
      assignedOrders:
          orders.where((o) => OrderStatusMapper.isAssigned(o.status)).length,
      completedOrders:
          orders.where((o) => OrderStatusMapper.isCompleted(o.status)).length,
      courierRequests: pendingCouriers.length,
      topups: pendingTopups.length,
      recentOrders: orders.take(3).toList(growable: false),
    );
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DashboardData>(
      future: _future,
      builder: (context, snap) {
        final data = snap.data;
        return AdminListScaffold(
          title: widget.moderator ? 'Панель модератора' : 'Панель оператора',
          isLoading: snap.connectionState == ConnectionState.waiting,
          error: snap.hasError
              ? userErrorMessage(
                  snap.error!,
                  fallback: 'Не удалось загрузить панель',
                )
              : null,
          onRefresh: _refresh,
          header: data == null
              ? null
              : _DashboardHeader(data: data, moderator: widget.moderator),
          children: [
            if (data != null) ...[
              _QuickActionCard(
                title: 'Пополнения на проверку',
                subtitle: widget.moderator
                    ? 'Ожидают решения: ${data.topups}'
                    : 'Доступно модератору',
                icon: Icons.payments_outlined,
                color: AppColors.success,
                enabled: widget.moderator,
                onTap: () => context.go('/app/moderator/finance'),
              ),
              _QuickActionCard(
                title: 'Заявки курьеров',
                subtitle: 'Ожидают проверки: ${data.courierRequests}',
                icon: Icons.verified_user_outlined,
                color: AppColors.courier,
                enabled: !widget.moderator,
                onTap: () => context.go('/app/operator/courier-requests'),
              ),
              _QuickActionCard(
                title: 'Все заказы',
                subtitle:
                    'Новые: ${data.newOrders}, активные: ${data.activeTotal}',
                icon: Icons.list_alt_outlined,
                color: AppColors.primary,
                onTap: () => context.go(
                  widget.moderator ? '/app/moderator/orders' : '/app/operator',
                ),
              ),
              if (widget.moderator)
                _QuickActionCard(
                  title: 'Пользователи',
                  subtitle: 'Карточки пользователей и роли',
                  icon: Icons.people_outline,
                  color: AppColors.info,
                  onTap: () => context.go('/app/moderator/users'),
                ),
              if (data.recentOrders.isEmpty)
                const AdminDataCard(
                  title: 'Проблемных событий пока нет',
                  subtitle:
                      'Когда появятся новые заказы или проверки, они будут здесь.',
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                )
              else
                for (final order in data.recentOrders)
                  AdminDataCard(
                    title: order.number,
                    subtitle: OrderStatusMapper.info(order.status).label,
                    trailing: order.priceFormatted,
                    icon: Icons.local_shipping_outlined,
                    color: OrderStatusMapper.info(order.status).textColor,
                  ),
            ],
          ],
        );
      },
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final _DashboardData data;
  final bool moderator;

  const _DashboardHeader({required this.data, required this.moderator});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          moderator
              ? 'Что нужно проверить сейчас'
              : 'Оперативная сводка заказов',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.75,
          children: [
            _MetricTile(
              label: 'Новые',
              value: data.newOrders,
              color: AppColors.info,
              icon: Icons.fiber_new_outlined,
            ),
            _MetricTile(
              label: 'Назначены',
              value: data.assignedOrders,
              color: AppColors.primary,
              icon: Icons.person_pin_circle_outlined,
            ),
            _MetricTile(
              label: 'В работе',
              value: data.activeOrders,
              color: AppColors.courier,
              icon: Icons.local_shipping_outlined,
            ),
            _MetricTile(
              label: moderator ? 'Пополнения' : 'Завершены',
              value: moderator ? data.topups : data.completedOrders,
              color: moderator ? AppColors.success : AppColors.success,
              icon: moderator
                  ? Icons.payments_outlined
                  : Icons.check_circle_outline,
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$value',
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return AdminDataCard(
      title: title,
      subtitle: enabled ? subtitle : '$subtitle. Недоступно для этой роли.',
      icon: icon,
      color: enabled ? color : AppColors.grayText,
      onTap: enabled ? onTap : null,
      actions: [
        FilledButton.icon(
          onPressed: enabled ? onTap : null,
          icon: const Icon(Icons.chevron_right, size: 18),
          label: Text(enabled ? 'Открыть' : 'Недоступно'),
        ),
      ],
    );
  }
}

class _DashboardData {
  final int newOrders;
  final int activeOrders;
  final int assignedOrders;
  final int completedOrders;
  final int courierRequests;
  final int topups;
  final List<OrderSummary> recentOrders;

  const _DashboardData({
    required this.newOrders,
    required this.activeOrders,
    required this.assignedOrders,
    required this.completedOrders,
    required this.courierRequests,
    required this.topups,
    required this.recentOrders,
  });

  int get activeTotal => activeOrders + assignedOrders;
}
