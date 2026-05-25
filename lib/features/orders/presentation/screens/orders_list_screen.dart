import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:citycargo_mobile/gen_l10n/app_localizations.dart';
import '../../../../shared/models/api_response_model.dart';
import '../../../../shared/models/order_status.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/order_card.dart';
import '../../../../shared/widgets/skeleton_order_card.dart';
import '../providers/orders_provider.dart';

class OrdersListScreen extends ConsumerStatefulWidget {
  final String? actorRole;
  final String? title;

  const OrdersListScreen({
    super.key,
    this.actorRole,
    this.title,
  });

  @override
  ConsumerState<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends ConsumerState<OrdersListScreen> {
  String? _filter;
  List<OrderSummary> _orders = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  String? _error;

  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _loadOrders(refresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadOrders();
    }
  }

  Future<void> _loadOrders({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _page = 1;
        _hasMore = true;
        _error = null;
      });
    } else {
      if (!_hasMore || _isLoading || _isLoadingMore) return;
      setState(() {
        _isLoadingMore = true;
        _page++;
      });
    }

    try {
      final newOrders = await ref.read(ordersRepositoryProvider).getOrders(
        role: widget.actorRole,
        page: _page,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            _orders = newOrders;
            _isLoading = false;
          } else {
            _orders.addAll(newOrders);
            _isLoadingMore = false;
          }
          _hasMore = newOrders.length == 20;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          if (refresh) {
            _isLoading = false;
          } else {
            _isLoadingMore = false;
            _page--;
          }
        });
      }
    }
  }

  Future<void> _refresh() async {
    await _loadOrders(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filters = [
      _FilterItem('all', l10n.all),
      _FilterItem('new', l10n.filterNew),
      _FilterItem('active', l10n.filterActive),
      _FilterItem('done', l10n.filterDone),
      _FilterItem('cancelled', l10n.filterCancelled),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? l10n.orders)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FilterBar(
            items: filters,
            selected: _filter ?? 'all',
            onChanged: (value) {
              setState(() => _filter = value == 'all' ? null : value);
            },
          ),
          Expanded(
            child: _buildBody(l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (_, __) => const SkeletonOrderCard(),
      );
    }
    if (_error != null && _orders.isEmpty) {
      return AppErrorWidget(
        message: _error!,
        onRetry: _refresh,
      );
    }
    final visibleOrders = _visibleOrders(_orders);
    if (visibleOrders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 96),
            EmptyStateWidget(
              title: l10n.noOrdersTitle,
              subtitle: l10n.refreshHint,
              icon: Icons.inbox_outlined,
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: visibleOrders.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == visibleOrders.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final order = visibleOrders[i];
          return OrderCard(
            order: order,
            onTap: () {
              if (order.number.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.errorNoOrderNumber),
                  ),
                );
                return;
              }
              context.push('/orders/${Uri.encodeComponent(order.number)}');
            },
          )
          .animate(key: ValueKey(order.number))
          .fade(duration: 300.ms, delay: (i * 50).ms)
          .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad, duration: 400.ms);
        },
      ),
    );
  }

  List<OrderSummary> _visibleOrders(List<OrderSummary> orders) {
    return orders.where((order) {
      final status = order.status;
      return switch (_filter) {
        null || 'all' => true,
        'new' => OrderStatusMapper.isCreated(status) ||
            OrderStatusMapper.isAssigned(status),
        'active' => OrderStatusMapper.isInProgress(status),
        'done' => OrderStatusMapper.isCompleted(status),
        'cancelled' => OrderStatusMapper.isCancelled(status),
        _ => true,
      };
    }).toList();
  }
}

class _FilterBar extends StatelessWidget {
  final List<_FilterItem> items;
  final String? selected;
  final ValueChanged<String> onChanged;

  const _FilterBar({
    required this.items,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 54,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = selected == item.value;
          return ChoiceChip(
            label: Text(item.label),
            selected: isSelected,
            showCheckmark: false,
            selectedColor: theme.colorScheme.onSurface,
            backgroundColor: theme.cardColor,
            side: BorderSide(color: theme.dividerColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            labelStyle: TextStyle(
              color: isSelected
                  ? theme.colorScheme.surface
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            ),
            onSelected: (_) => onChanged(item.value),
          );
        },
      ),
    );
  }
}

class _FilterItem {
  final String value;
  final String label;

  const _FilterItem(this.value, this.label);
}
