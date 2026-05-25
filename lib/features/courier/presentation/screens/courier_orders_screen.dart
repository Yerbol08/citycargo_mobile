import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../features/orders/presentation/providers/orders_provider.dart';
import '../../../../shared/models/api_response_model.dart';
import '../../../../shared/models/order_status.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/order_card.dart';
import '../../../../shared/widgets/skeleton_order_card.dart';

class CourierOrdersScreen extends ConsumerStatefulWidget {
  const CourierOrdersScreen({super.key});

  @override
  ConsumerState<CourierOrdersScreen> createState() =>
      _CourierOrdersScreenState();
}

class _CourierOrdersScreenState extends ConsumerState<CourierOrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted) _load(refresh: true);
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) {
    return ref.read(courierOrdersProvider.notifier).load(refresh: refresh);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(courierOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Заказы'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            icon: const Icon(Icons.refresh),
            onPressed: state.isRefreshing ? null : () => _load(refresh: true),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.courier,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.courier,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Новые'),
            Tab(text: 'Мои'),
            Tab(text: 'В работе'),
            Tab(text: 'Завершённые'),
          ],
        ),
      ),
      body: state.isLoading
          ? ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: 5,
              itemBuilder: (_, __) => const SkeletonOrderCard(),
            )
          : state.error != null
              ? AppErrorWidget(
                  message: state.error!,
                  onRetry: _load,
                )
              : Stack(
                  children: [
                    TabBarView(
                      controller: _tab,
                      children: [
                        _OrderList(
                          orders: state.orders
                              .where(
                                  (o) => OrderStatusMapper.isCreated(o.status))
                              .toList(),
                          onRefresh: () => _load(refresh: true),
                        ),
                        _OrderList(
                          orders: state.orders
                              .where(
                                  (o) => OrderStatusMapper.isAssigned(o.status))
                              .toList(),
                          onRefresh: () => _load(refresh: true),
                        ),
                        _OrderList(
                          orders: state.orders
                              .where((o) =>
                                  OrderStatusMapper.isInProgress(o.status))
                              .toList(),
                          onRefresh: () => _load(refresh: true),
                        ),
                        _OrderList(
                          orders: state.orders
                              .where((o) =>
                                  OrderStatusMapper.isCompleted(o.status))
                              .toList(),
                          onRefresh: () => _load(refresh: true),
                        ),
                      ],
                    ),
                    if (state.isRefreshing)
                      const Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        child: LinearProgressIndicator(
                          color: AppColors.courier,
                          minHeight: 2,
                        ),
                      ),
                  ],
                ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<OrderSummary> orders;
  final Future<void> Function() onRefresh;

  const _OrderList({
    required this.orders,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 96),
            EmptyStateWidget(
              title: 'Заказов пока нет',
              subtitle: 'Потяните вниз, чтобы обновить список.',
              icon: Icons.inbox_outlined,
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: orders.length,
        itemBuilder: (ctx, i) => OrderCard(
          order: orders[i],
          onTap: () {
            final order = orders[i];
            if (order.number.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Не удалось открыть заказ: сервер не вернул номер заказа',
                  ),
                ),
              );
              return;
            }
            final encodedNumber = Uri.encodeComponent(order.number);
            debugPrint('NAVIGATE TO ORDER: ${order.number}');
            context.push('/courier/orders/$encodedNumber');
          },
        ),
      ),
    );
  }
}
