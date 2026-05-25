import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../shared/models/order_status.dart';
import '../providers/admin_provider.dart';
import '../../../../shared/models/api_response_model.dart';

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
    return Scaffold(
      body: FutureBuilder<_DashboardData>(
        future: _future,
        builder: (context, snap) {
          final isLoading = snap.connectionState == ConnectionState.waiting;
          final error = snap.hasError ? snap.error : null;
          final data = snap.data;

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildSliverAppBar(),
                if (isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (error != null)
                  SliverFillRemaining(
                    child: _buildErrorState(error),
                  )
                else if (data != null)
                  _buildContent(data),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 140.0,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ],
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16, right: 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.moderator ? 'С возвращением!' : 'Сводка оператора',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.moderator ? 'Панель Модератора' : 'Контроль Заказов',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _refresh,
          tooltip: 'Обновить',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 40),
            const SizedBox(height: 12),
            Text(
              userErrorMessage(error, fallback: 'Не удалось загрузить панель'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.danger),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refresh,
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(_DashboardData data) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildMetricsSection(data),
          const SizedBox(height: 16),
          _buildQuickActionsSection(data),
          const SizedBox(height: 16),
          _buildChartPlaceholder(),
          const SizedBox(height: 16),
          _buildRecentOrdersSection(data),
        ]),
      ),
    );
  }

  Widget _buildMetricsSection(_DashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Оперативная сводка',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _GlassMetricTile(
              label: 'Новые',
              value: data.newOrders,
              color: AppColors.info,
              icon: Icons.fiber_new_outlined,
            ),
            _GlassMetricTile(
              label: 'Назначены',
              value: data.assignedOrders,
              color: AppColors.primary,
              icon: Icons.person_pin_circle_outlined,
            ),
            _GlassMetricTile(
              label: 'В работе',
              value: data.activeOrders,
              color: AppColors.courier,
              icon: Icons.local_shipping_outlined,
            ),
            _GlassMetricTile(
              label: widget.moderator ? 'Пополнения' : 'Завершены',
              value: widget.moderator ? data.topups : data.completedOrders,
              color: widget.moderator ? AppColors.warning : AppColors.success,
              icon: widget.moderator
                  ? Icons.payments_outlined
                  : Icons.check_circle_outline,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(_DashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Быстрые действия',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            _QuickActionSquare(
              title: 'Финансы',
              subtitle: '${data.topups} ожидают',
              icon: Icons.account_balance_wallet_outlined,
              color: AppColors.success,
              enabled: widget.moderator,
              onTap: () => context.go('/app/moderator/finance'),
            ),
            _QuickActionSquare(
              title: 'Заказы',
              subtitle: '${data.activeTotal} активных',
              icon: Icons.inventory_2_outlined,
              color: AppColors.primary,
              enabled: true,
              onTap: () => context.go(
                widget.moderator ? '/app/moderator/orders' : '/app/operator',
              ),
            ),
            _QuickActionSquare(
              title: 'Курьеры',
              subtitle: '${data.courierRequests} заявок',
              icon: Icons.delivery_dining_outlined,
              color: AppColors.courier,
              enabled: !widget.moderator,
              onTap: () => context.go('/app/operator/courier-requests'),
            ),
            _QuickActionSquare(
              title: 'Сотрудники',
              subtitle: 'Роли и доступы',
              icon: Icons.groups_outlined,
              color: AppColors.info,
              enabled: widget.moderator,
              onTap: () => context.go('/app/moderator/users'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartPlaceholder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Аналитика (Скоро)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart_rounded,
                size: 48,
                color: AppColors.textSecondary.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              Text(
                'Здесь будет график доходов\nи статистика заказов за неделю',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentOrdersSection(_DashboardData data) {
    if (data.recentOrders.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Недавние заказы',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            TextButton(
              onPressed: () => context.go(
                widget.moderator ? '/app/moderator/orders' : '/app/operator',
              ),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('Все', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            child: Column(
              children: [
                for (var i = 0; i < data.recentOrders.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _RecentOrderTile(order: data.recentOrders[i]),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassMetricTile extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _GlassMetricTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background soft circle
          Positioned(
            right: -10,
            bottom: -10,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 16),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$value',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionSquare extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;

  const _QuickActionSquare({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Container(
        decoration: BoxDecoration(
          color: enabled
              ? Theme.of(context).cardTheme.color
              : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: enabled ? color.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                enabled ? icon : Icons.lock_outline,
                color: enabled ? color : Colors.grey.shade500,
                size: 24,
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: enabled
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              enabled ? subtitle : 'Нет доступа',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: enabled ? AppColors.textSecondary : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentOrderTile extends StatelessWidget {
  final OrderSummary order;

  const _RecentOrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final statusInfo = OrderStatusMapper.info(order.status);
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: statusInfo.textColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.local_shipping_outlined, color: statusInfo.textColor, size: 20),
      ),
      title: Text(
        order.number,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            statusInfo.label,
            style: TextStyle(color: statusInfo.textColor, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            order.priceFormatted,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          const SizedBox(height: 4),
          const Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondary),
        ],
      ),
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
