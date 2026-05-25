import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../shared/models/api_response_model.dart';
import '../../../../shared/models/order_status.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_cards.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  final bool moderator;

  const AdminOrdersScreen({super.key, required this.moderator});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  final _phoneCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  String _status = '';
  late Future<List<OrderSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _numberCtrl.dispose();
    super.dispose();
  }

  Future<List<OrderSummary>> _load() {
    return ref.read(adminRepositoryProvider).getOrders(
          status: _status,
          phone: _phoneCtrl.text.trim(),
        );
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _assignCourier(OrderSummary order) async {
    final repo = ref.read(adminRepositoryProvider);
    final couriers = await repo.getCouriers();
    if (!mounted) return;
    if (couriers.isEmpty) {
      _snack(
          '\u041d\u0435\u0442 \u0434\u043e\u0441\u0442\u0443\u043f\u043d\u044b\u0445 \u043a\u0443\u0440\u044c\u0435\u0440\u043e\u0432');
      return;
    }
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      showDragHandle: true,
      builder: (_) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '\u041d\u0430\u0437\u043d\u0430\u0447\u0438\u0442\u044c \u043a\u0443\u0440\u044c\u0435\u0440\u0430',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          for (final courier in couriers)
            ListTile(
              leading: const Icon(Icons.delivery_dining),
              title: Text(_text(courier, ['full_name', 'name', 'phone'])),
              subtitle: Text(
                _text(courier, ['phone', 'status', 'transport_type']),
              ),
              onTap: () => Navigator.pop(context, courier),
            ),
        ],
      ),
    );
    if (selected == null) return;
    try {
      await repo.assignCourier(
        orderId: order.id,
        courierId: _text(selected, ['user_id', 'courier_id', 'id']),
        vehicleId: _nullableText(selected, ['vehicle_id']),
      );
      final note = _status == 'created'
          ? '\n\u0417\u0430\u043a\u0430\u0437 \u0443\u0439\u0434\u0435\u0442 \u0438\u0437 \u0444\u0438\u043b\u044c\u0442\u0440\u0430 "\u041d\u043e\u0432\u044b\u0435", \u0442\u0430\u043a \u043a\u0430\u043a \u0441\u0442\u0430\u0442\u0443\u0441 \u0438\u0437\u043c\u0435\u043d\u0438\u043b\u0441\u044f.'
          : '';
      _snack(
          '\u041a\u0443\u0440\u044c\u0435\u0440 \u043d\u0430\u0437\u043d\u0430\u0447\u0435\u043d$note');
      _refresh();
    } catch (_) {
      _snack(
        '\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u043d\u0430\u0437\u043d\u0430\u0447\u0438\u0442\u044c \u043a\u0443\u0440\u044c\u0435\u0440\u0430',
        error: true,
      );
    }
  }

  Future<void> _changeStatus(OrderSummary order) async {
    final repo = ref.read(adminRepositoryProvider);
    var statuses = <Map<String, dynamic>>[];
    try {
      statuses = await repo.getOrderStatuses();
    } catch (_) {
      statuses = const [
        {'code': 'created', 'name': '\u0421\u043e\u0437\u0434\u0430\u043d'},
        {
          'code': 'assigned_to_courier',
          'name':
              '\u041a\u0443\u0440\u044c\u0435\u0440 \u043d\u0430\u0437\u043d\u0430\u0447\u0435\u043d',
        },
        {
          'code': 'in_progress',
          'name': '\u0412 \u0440\u0430\u0431\u043e\u0442\u0435',
        },
        {'code': 'picked_up', 'name': '\u0417\u0430\u0431\u0440\u0430\u043d'},
        {
          'code': 'delivery_in_progress',
          'name': '\u0412 \u0434\u043e\u0441\u0442\u0430\u0432\u043a\u0435',
        },
        {
          'code': 'delivered',
          'name': '\u0414\u043e\u0441\u0442\u0430\u0432\u043b\u0435\u043d'
        },
        {
          'code': 'completed',
          'name': '\u0417\u0430\u0432\u0435\u0440\u0448\u0435\u043d',
        },
        {
          'code': 'cancelled',
          'name': '\u041e\u0442\u043c\u0435\u043d\u0435\u043d'
        },
      ];
    }
    statuses = statuses.where((status) {
      final code = _text(status, ['code', 'status_code']);
      return code != 'accepted' &&
          code != 'pickup_in_progress' &&
          _isKnownStatusTransitionAllowed(order.status, code);
    }).toList();
    if (!mounted) return;
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      showDragHandle: true,
      builder: (_) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '\u0418\u0437\u043c\u0435\u043d\u0438\u0442\u044c \u0441\u0442\u0430\u0442\u0443\u0441',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          for (final status in statuses)
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: Text(_text(status, ['name', 'title', 'label', 'code'])),
              subtitle: Text(_text(status, ['code', 'status_code'])),
              onTap: () => Navigator.pop(context, status),
            ),
        ],
      ),
    );
    if (selected == null) return;
    final code = _text(selected, ['code', 'status_code']);
    try {
      await repo.changeOrderStatus(
        orderId: order.id,
        status: code,
        reason:
            '\u0418\u0437\u043c\u0435\u043d\u0435\u043d\u043e \u043e\u043f\u0435\u0440\u0430\u0442\u043e\u0440\u043e\u043c',
      );
      _snack(
          '\u0421\u0442\u0430\u0442\u0443\u0441 \u0438\u0437\u043c\u0435\u043d\u0435\u043d');
      _refresh();
    } catch (_) {
      _snack(
        '\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u0438\u0437\u043c\u0435\u043d\u0438\u0442\u044c \u0441\u0442\u0430\u0442\u0443\u0441',
        error: true,
      );
    }
  }

  bool _isKnownStatusTransitionAllowed(String currentRaw, String nextRaw) {
    final current = OrderStatusMapper.normalize(currentRaw);
    final next = OrderStatusMapper.normalize(nextRaw);
    if (current == next) return false;

    return switch (current) {
      'created' => next == 'assigned_to_courier' || next == 'cancelled',
      'assigned_to_courier' => next == 'cancelled',
      'in_progress' => next == 'cancelled',
      'picked_up' => next == 'cancelled',
      'delivery_in_progress' => next == 'cancelled',
      'delivered' => next == 'completed',
      'completed' || 'cancelled' => false,
      _ => next == 'cancelled',
    };
  }

  Future<void> _showModeratorOrderTools(OrderSummary order) async {
    final repo = ref.read(adminRepositoryProvider);
    try {
      final results = await Future.wait([
        repo.getOrderHistory(order.number),
        repo.getSecurityCodes(order.id).then((v) => [v]),
      ]);
      if (!mounted) return;
      final history = results[0];
      final codes = results[1].isEmpty ? <String, dynamic>{} : results[1].first;
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              order.number,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            const Text(
              '\u041a\u043e\u0434\u044b \u0431\u0435\u0437\u043e\u043f\u0430\u0441\u043d\u043e\u0441\u0442\u0438',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              codes.isEmpty
                  ? '\u041a\u043e\u0434\u044b \u043d\u0435 \u043d\u0430\u0439\u0434\u0435\u043d\u044b'
                  : codes.entries.map((e) => '${e.key}: ${e.value}').join('\n'),
            ),
            const SizedBox(height: 16),
            const Text(
              '\u0418\u0441\u0442\u043e\u0440\u0438\u044f',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            if (history.isEmpty)
              const Text(
                '\u0418\u0441\u0442\u043e\u0440\u0438\u044f \u043f\u043e\u043a\u0430 \u043f\u0443\u0441\u0442\u0430\u044f',
              )
            else
              for (final item in history)
                ListTile(
                  dense: true,
                  title: Text(
                    _text(item, ['action', 'event', 'status_code', 'type']),
                  ),
                  subtitle: Text(_compact(item)),
                ),
          ],
        ),
      );
    } catch (_) {
      _snack(
        '\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u043e\u0442\u043a\u0440\u044b\u0442\u044c \u0434\u0430\u043d\u043d\u044b\u0435 \u043c\u043e\u0434\u0435\u0440\u0430\u0442\u043e\u0440\u0430',
        error: true,
      );
    }
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.danger : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<OrderSummary>>(
      future: _future,
      builder: (context, snap) {
        var orders = snap.data ?? const <OrderSummary>[];
        final number = _numberCtrl.text.trim().toLowerCase();
        if (number.isNotEmpty) {
          orders = orders
              .where((order) => order.number.toLowerCase().contains(number))
              .toList();
        }
        return AdminListScaffold(
          title: widget.moderator
              ? '\u0417\u0430\u043a\u0430\u0437\u044b \u043c\u043e\u0434\u0435\u0440\u0430\u0442\u043e\u0440\u0430'
              : '\u0417\u0430\u043a\u0430\u0437\u044b \u043e\u043f\u0435\u0440\u0430\u0442\u043e\u0440\u0430',
          isLoading: snap.connectionState == ConnectionState.waiting,
          error: snap.hasError
              ? userErrorMessage(
                  snap.error!,
                  fallback: 'Не удалось загрузить заказы',
                )
              : null,
          onRefresh: _refresh,
          header: _Filters(
            phoneCtrl: _phoneCtrl,
            numberCtrl: _numberCtrl,
            status: _status,
            onStatusChanged: (value) {
              _status = value;
              _refresh();
            },
            onSearch: _refresh,
            showHistoryHint: widget.moderator,
          ),
          children: [
            for (final order in orders)
              AdminDataCard(
                title: order.number,
                subtitle: '${order.senderAddress}\n${order.recipientAddress}',
                trailing: order.priceFormatted,
                icon: Icons.local_shipping_outlined,
                color: _statusColor(order.status),
                onTap: () {
                  if (order.number.isEmpty) return;
                  context.push('/orders/${Uri.encodeComponent(order.number)}');
                },
                actions: [
                  if (widget.moderator)
                    OutlinedButton.icon(
                      onPressed: () => _showModeratorOrderTools(order),
                      icon: const Icon(Icons.manage_search, size: 18),
                      label: const Text(
                          '\u041a\u043e\u043d\u0442\u0440\u043e\u043b\u044c'),
                    ),
                  if (!widget.moderator)
                    OutlinedButton.icon(
                      onPressed: () => _assignCourier(order),
                      icon: const Icon(Icons.person_add_alt, size: 18),
                      label: const Text(
                          '\u041d\u0430\u0437\u043d\u0430\u0447\u0438\u0442\u044c'),
                    ),
                  if (!widget.moderator)
                    OutlinedButton.icon(
                      onPressed: () => _changeStatus(order),
                      icon: const Icon(Icons.sync_alt, size: 18),
                      label: const Text('\u0421\u0442\u0430\u0442\u0443\u0441'),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }

  Color _statusColor(String status) {
    return switch (status) {
      'created' => AppColors.primary,
      'delivered' || 'completed' => AppColors.success,
      'cancelled' => AppColors.danger,
      _ => AppColors.textSecondary,
    };
  }

  String _text(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return '-';
  }

  String? _nullableText(Map<String, dynamic> json, List<String> keys) {
    final value = _text(json, keys);
    return value == '-' ? null : value;
  }

  String _compact(Map<String, dynamic> json) {
    final priority = [
      'created_at',
      'createdAt',
      'reason',
      'comment',
      'actor_name',
      'actor_id',
      'from_status',
      'to_status',
      'status_code',
    ];
    final lines = <String>[];
    for (final key in priority) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        lines.add('$key: $value');
      }
    }
    return lines.isEmpty ? 'Подробностей нет' : lines.take(4).join('\n');
  }
}

class _Filters extends StatelessWidget {
  final TextEditingController phoneCtrl;
  final TextEditingController numberCtrl;
  final String status;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onSearch;
  final bool showHistoryHint;

  const _Filters({
    required this.phoneCtrl,
    required this.numberCtrl,
    required this.status,
    required this.onStatusChanged,
    required this.onSearch,
    required this.showHistoryHint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: '\u0422\u0435\u043b\u0435\u0444\u043e\u043d',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                onSubmitted: (_) => onSearch(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: numberCtrl,
                decoration: const InputDecoration(
                  labelText: '\u041d\u043e\u043c\u0435\u0440',
                  prefixIcon: Icon(Icons.tag),
                ),
                onSubmitted: (_) => onSearch(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: onSearch,
              icon: const Icon(Icons.search),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: '', label: Text('\u0412\u0441\u0435')),
            ButtonSegment(
                value: 'created',
                label: Text('\u041d\u043e\u0432\u044b\u0435')),
            ButtonSegment(
              value: 'delivered',
              label: Text('\u0414\u043e\u0441\u0442\u0430\u0432\u043b.'),
            ),
          ],
          selected: {status},
          onSelectionChanged: (value) => onStatusChanged(value.first),
        ),
        if (showHistoryHint) ...[
          const SizedBox(height: 8),
          const Text(
            '\u0418\u0441\u0442\u043e\u0440\u0438\u044f \u0438 \u043a\u043e\u0434\u044b \u0434\u043e\u0441\u0442\u0443\u043f\u043d\u044b \u0447\u0435\u0440\u0435\u0437 \u043a\u043d\u043e\u043f\u043a\u0443 "\u041a\u043e\u043d\u0442\u0440\u043e\u043b\u044c".',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ],
    );
  }
}
