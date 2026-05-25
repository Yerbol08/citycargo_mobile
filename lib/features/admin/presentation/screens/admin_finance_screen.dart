import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/error_messages.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_cards.dart';

class AdminFinanceScreen extends ConsumerStatefulWidget {
  const AdminFinanceScreen({super.key});

  @override
  ConsumerState<AdminFinanceScreen> createState() => _AdminFinanceScreenState();
}

class _AdminFinanceScreenState extends ConsumerState<AdminFinanceScreen> {
  final _phoneCtrl = TextEditingController();
  final Set<String> _busyTopupIds = {};
  final Map<String, Map<String, String>> _localTopupOverrides = {};
  String? _status;
  late Future<_FinanceData> _future;
  _FinanceData? _lastData;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<_FinanceData> _load() async {
    final repo = ref.read(adminRepositoryProvider);
    final topups = await repo.getTopups(
      status: _status,
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
    );
    final pricing = await repo.getPricing();
    final commission = await repo.getCommissionReport();
    final normalizedTopups = topups.map(_applyTopupOverride).toList();
    final data = _FinanceData(
      topups: _applyTopupFilter(normalizedTopups),
      pricing: pricing,
      commission: commission,
    );
    _lastData = data;
    return data;
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _showTopup(Map<String, dynamic> topup) async {
    final id = _id(topup);
    if (!_hasId(id)) return _showSnack('Не найден ID заявки');
    try {
      final details = await ref.read(adminRepositoryProvider).getTopup(id);
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) => SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            shrinkWrap: true,
            children: [
              const Text(
                'Заявка на пополнение',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              AdminDataCard(
                title: _money(details),
                subtitle: _compact(details),
                trailing: _topupStatusLabel(_topupStatus(details)),
                icon: Icons.payments_outlined,
                color: _topupStatusColor(details),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      _showSnack(
        userErrorMessage(e, fallback: 'Не удалось открыть заявку'),
        error: true,
      );
    }
  }

  Future<void> _confirmTopup(Map<String, dynamic> topup) async {
    final id = _id(topup);
    if (!_hasId(id)) return _showSnack('Не найден ID заявки');
    if (!_isPendingTopup(topup)) {
      return _showSnack('Эта заявка уже обработана');
    }

    setState(() => _busyTopupIds.add(id));
    try {
      await ref.read(adminRepositoryProvider).confirmTopup(id);
      _localTopupOverrides[id] = {'status': 'confirmed'};
      _applyTopupStatusLocally(id, 'confirmed');
      _showSnack('Пополнение подтверждено');
    } catch (e) {
      _showSnack(
        userErrorMessage(e, fallback: 'Не удалось подтвердить пополнение'),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() => _busyTopupIds.remove(id));
      }
    }
  }

  Future<void> _rejectTopup(Map<String, dynamic> topup) async {
    final id = _id(topup);
    if (!_hasId(id)) return _showSnack('Не найден ID заявки');
    if (!_isPendingTopup(topup)) {
      return _showSnack('Эта заявка уже обработана');
    }

    final reason = await _askReason('Причина отклонения');
    if (reason == null) return;

    setState(() => _busyTopupIds.add(id));
    try {
      await ref.read(adminRepositoryProvider).rejectTopup(id, reason);
      _localTopupOverrides[id] = {'status': 'rejected', 'reason': reason};
      _applyTopupStatusLocally(id, 'rejected', reason: reason);
      _showSnack('Пополнение отклонено');
    } catch (e) {
      _showSnack(
        userErrorMessage(e, fallback: 'Не удалось отклонить пополнение'),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() => _busyTopupIds.remove(id));
      }
    }
  }

  void _applyTopupStatusLocally(
    String id,
    String status, {
    String? reason,
  }) {
    final current = _lastData;
    if (current == null) return;

    final topups = current.topups
        .map((item) {
          if (_id(item) != id) return item;
          return {
            ...item,
            'status': status,
            'status_code': status,
            if (reason != null && reason.isNotEmpty) 'reason': reason,
          };
        })
        .where(_matchesCurrentStatusFilter)
        .toList();

    final updated = current.copyWith(topups: topups);
    setState(() {
      _lastData = updated;
      _future = Future.value(updated);
    });
  }

  Map<String, dynamic> _applyTopupOverride(Map<String, dynamic> item) {
    final override = _localTopupOverrides[_id(item)];
    if (override == null) return item;
    return {
      ...item,
      'status': override['status'],
      'status_code': override['status'],
      if (override['reason'] != null) 'reason': override['reason'],
    };
  }

  Future<void> _editPricing(Map<String, dynamic> pricing) async {
    final orderCtrl = TextEditingController(
      text: _text(pricing, ['order_price_minor']),
    );
    final rewardCtrl = TextEditingController(
      text: _text(pricing, ['courier_reward_minor']),
    );
    final commissionCtrl = TextEditingController(
      text: _text(pricing, ['system_commission_minor']),
    );
    final currencyCtrl = TextEditingController(
      text: _text(pricing, ['currency_code']).replaceAll('-', 'KZT'),
    );
    final scenarioCtrl = TextEditingController(
      text: _text(pricing, ['scenario_code']).replaceAll('-', 'default'),
    );

    final body = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Обновить тариф'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _amountField(orderCtrl, 'Цена заказа, тиын'),
              const SizedBox(height: 10),
              _amountField(rewardCtrl, 'Вознаграждение курьера, тиын'),
              const SizedBox(height: 10),
              _amountField(commissionCtrl, 'Комиссия системы, тиын'),
              const SizedBox(height: 10),
              TextField(
                controller: currencyCtrl,
                decoration: const InputDecoration(labelText: 'Валюта'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: scenarioCtrl,
                decoration: const InputDecoration(labelText: 'Сценарий'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              final order = int.tryParse(orderCtrl.text.trim());
              final reward = int.tryParse(rewardCtrl.text.trim());
              final commission = int.tryParse(commissionCtrl.text.trim());
              if (order == null || reward == null || commission == null) {
                return;
              }
              Navigator.pop(context, {
                'order_price_minor': order,
                'courier_reward_minor': reward,
                'system_commission_minor': commission,
                'currency_code': currencyCtrl.text.trim().isEmpty
                    ? 'KZT'
                    : currencyCtrl.text.trim(),
                'scenario_code': scenarioCtrl.text.trim().isEmpty
                    ? 'default'
                    : scenarioCtrl.text.trim(),
              });
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    orderCtrl.dispose();
    rewardCtrl.dispose();
    commissionCtrl.dispose();
    currencyCtrl.dispose();
    scenarioCtrl.dispose();

    if (body == null) return;
    try {
      await ref.read(adminRepositoryProvider).updatePricing(body);
      _showSnack('Тариф обновлен');
      _refresh();
    } catch (e) {
      _showSnack(
        userErrorMessage(e, fallback: 'Не удалось обновить тариф'),
        error: true,
      );
    }
  }

  Widget _amountField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label),
    );
  }

  Future<String?> _askReason(String title) {
    return showDialog<String>(
      context: context,
      builder: (context) => _ReasonDialog(title: title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_FinanceData>(
      future: _future,
      builder: (context, snap) {
        final data = snap.data ?? _lastData;
        return AdminListScaffold(
          title: 'Финансы',
          isLoading: snap.connectionState == ConnectionState.waiting &&
              _lastData == null,
          error: snap.hasError
              ? userErrorMessage(
                  snap.error!,
                  fallback: 'Не удалось загрузить финансы',
                )
              : null,
          onRefresh: _refresh,
          header: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FinanceFilters(
                phoneCtrl: _phoneCtrl,
                status: _status,
                onStatusChanged: (value) => setState(() {
                  _status = value;
                  _future = _load();
                }),
                onApply: _refresh,
              ),
              const SizedBox(height: 12),
              if (data != null)
                AdminDataCard(
                  title: 'Текущий тариф',
                  subtitle: _pricingText(data.pricing),
                  icon: Icons.price_change_outlined,
                  color: AppColors.success,
                  actions: [
                    FilledButton.icon(
                      onPressed: () => _editPricing(data.pricing),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Изменить тариф'),
                    ),
                  ],
                ),
              if (data != null)
                AdminDataCard(
                  title: 'Системный кошелек',
                  subtitle: data.commission.isEmpty
                      ? 'Комиссий пока нет'
                      : 'Записей комиссии: ${data.commission.length}',
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppColors.primary,
                ),
            ],
          ),
          children: [
            if (data != null)
              for (final topup in data.topups) _topupCard(topup),
            if (data != null && data.commission.isNotEmpty)
              for (final item in data.commission.take(10))
                AdminDataCard(
                  title: _text(item, ['order_number', 'id', 'created_at']),
                  subtitle: _compact(item),
                  icon: Icons.receipt_long_outlined,
                  color: AppColors.primary,
                ),
          ],
        );
      },
    );
  }

  Widget _topupCard(Map<String, dynamic> topup) {
    final id = _id(topup);
    final pending = _isPendingTopup(topup);
    final busy = _busyTopupIds.contains(id);
    final status = _topupStatus(topup);
    final color = _topupStatusColor(topup);

    return AdminDataCard(
      title: 'Пополнение ${_money(topup)}',
      subtitle: [
        _text(topup, ['phone', 'user_phone', 'user_id']),
        _text(topup, ['comment', 'reason']),
      ].where((v) => v != '-').join('\n'),
      trailing: _topupStatusLabel(status),
      icon: Icons.payments_outlined,
      color: color,
      onTap: () => _showTopup(topup),
      actions: [
        TextButton.icon(
          onPressed: busy ? null : () => _showTopup(topup),
          icon: const Icon(Icons.visibility_outlined, size: 18),
          label: const Text('Детали'),
        ),
        if (pending) ...[
          FilledButton.icon(
            onPressed: busy ? null : () => _confirmTopup(topup),
            icon: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check, size: 18),
            label: const Text('Подтвердить'),
          ),
          OutlinedButton.icon(
            onPressed: busy ? null : () => _rejectTopup(topup),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Отклонить'),
          ),
        ] else
          Chip(
            avatar: Icon(_processedIcon(status), size: 16, color: color),
            label: const Text('Заявка обработана'),
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }

  List<Map<String, dynamic>> _applyTopupFilter(
    List<Map<String, dynamic>> items,
  ) {
    return items.where(_matchesCurrentStatusFilter).toList();
  }

  bool _matchesCurrentStatusFilter(Map<String, dynamic> topup) {
    final filter = _status;
    if (filter == null || filter.isEmpty) return true;
    if (filter == 'pending') return _isPendingTopup(topup);
    if (filter == 'confirmed') return _isConfirmedTopup(topup);
    if (filter == 'rejected') return _isRejectedTopup(topup);
    return _topupStatus(topup) == filter;
  }

  bool _isPendingTopup(Map<String, dynamic> topup) {
    const pending = {
      'pending',
      'created',
      'new',
      'waiting',
      'awaiting',
      'in_review',
      'requested',
    };
    return pending.contains(_topupStatus(topup));
  }

  bool _isConfirmedTopup(Map<String, dynamic> topup) {
    const confirmed = {
      'confirmed',
      'approved',
      'completed',
      'paid',
      'success',
      'succeeded',
    };
    return confirmed.contains(_topupStatus(topup));
  }

  bool _isRejectedTopup(Map<String, dynamic> topup) {
    const rejected = {
      'rejected',
      'declined',
      'cancelled',
      'canceled',
      'failed',
    };
    return rejected.contains(_topupStatus(topup));
  }

  Color _topupStatusColor(Map<String, dynamic> topup) {
    if (_isPendingTopup(topup)) return AppColors.warning;
    if (_isConfirmedTopup(topup)) return AppColors.success;
    if (_isRejectedTopup(topup)) return AppColors.danger;
    return AppColors.primary;
  }

  IconData _processedIcon(String status) {
    if (_isRejectedStatus(status)) return Icons.close;
    return Icons.check;
  }

  bool _isRejectedStatus(String status) {
    return const {
      'rejected',
      'declined',
      'cancelled',
      'canceled',
      'failed',
    }.contains(status);
  }

  String _topupStatus(Map<String, dynamic> json) {
    return _text(json, ['status', 'status_code', 'state'])
        .toLowerCase()
        .trim()
        .replaceAll(' ', '_');
  }

  String _topupStatusLabel(String status) {
    switch (status) {
      case 'pending':
      case 'created':
      case 'new':
      case 'waiting':
      case 'awaiting':
      case 'in_review':
      case 'requested':
        return 'Ожидает';
      case 'confirmed':
      case 'approved':
      case 'completed':
      case 'paid':
      case 'success':
      case 'succeeded':
        return 'Подтверждено';
      case 'rejected':
      case 'declined':
      case 'cancelled':
      case 'canceled':
      case 'failed':
        return 'Отклонено';
      case '-':
      case '':
        return 'Без статуса';
      default:
        return status;
    }
  }

  bool _hasId(String value) => value.trim().isNotEmpty && value != '-';

  String _id(Map<String, dynamic> json) =>
      _text(json, ['id', 'topup_id', 'request_id']);

  String _money(Map<String, dynamic> json) {
    final raw = _text(json, ['amount_minor', 'amount']);
    final value = int.tryParse(raw);
    if (value == null) return raw;
    return '${(value / 100).toStringAsFixed(0)} KZT';
  }

  String _pricingText(Map<String, dynamic> pricing) {
    if (pricing.isEmpty) return 'Тариф не настроен';
    return [
      'Заказ: ${_moneyKey(pricing, 'order_price_minor')}',
      'Курьер: ${_moneyKey(pricing, 'courier_reward_minor')}',
      'Комиссия: ${_moneyKey(pricing, 'system_commission_minor')}',
      'Валюта: ${_text(pricing, ['currency_code'])}',
    ].join('\n');
  }

  String _moneyKey(Map<String, dynamic> json, String key) {
    final value = int.tryParse(json[key]?.toString() ?? '');
    if (value == null) return '-';
    return '${(value / 100).toStringAsFixed(0)} KZT';
  }

  String _text(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return '-';
  }

  String _compact(Map<String, dynamic> json) {
    const priority = [
      'id',
      'amount_minor',
      'amount',
      'status',
      'status_code',
      'phone',
      'user_phone',
      'comment',
      'reason',
      'created_at',
      'updated_at',
    ];
    final lines = <String>[];
    for (final key in priority) {
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        lines.add('$key: $value');
      }
    }
    return lines.isEmpty ? 'Детали заявки недоступны' : lines.join('\n');
  }

  void _showSnack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.danger : AppColors.success,
      ),
    );
  }
}

class _FinanceFilters extends StatelessWidget {
  final TextEditingController phoneCtrl;
  final String? status;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onApply;

  const _FinanceFilters({
    required this.phoneCtrl,
    required this.status,
    required this.onStatusChanged,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Телефон',
                prefixIcon: const Icon(Icons.phone_outlined),
                suffixIcon: IconButton(
                  onPressed: onApply,
                  icon: const Icon(Icons.search),
                ),
              ),
              onSubmitted: (_) => onApply(),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<String?>(
                selected: {status},
                segments: const [
                  ButtonSegment(value: null, label: Text('Все')),
                  ButtonSegment(value: 'pending', label: Text('Ожидают')),
                  ButtonSegment(value: 'confirmed', label: Text('Приняты')),
                  ButtonSegment(value: 'rejected', label: Text('Отклонены')),
                ],
                onSelectionChanged: (values) => onStatusChanged(values.first),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReasonDialog extends StatefulWidget {
  final String title;

  const _ReasonDialog({required this.title});

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        minLines: 2,
        maxLines: 4,
        decoration: const InputDecoration(
          labelText: 'Причина',
          hintText: 'Например: платеж не найден',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () {
            final text = _controller.text.trim();
            if (text.isNotEmpty) Navigator.pop(context, text);
          },
          child: const Text('Отправить'),
        ),
      ],
    );
  }
}

class _FinanceData {
  final List<Map<String, dynamic>> topups;
  final Map<String, dynamic> pricing;
  final List<Map<String, dynamic>> commission;

  const _FinanceData({
    required this.topups,
    required this.pricing,
    required this.commission,
  });

  _FinanceData copyWith({
    List<Map<String, dynamic>>? topups,
    Map<String, dynamic>? pricing,
    List<Map<String, dynamic>>? commission,
  }) {
    return _FinanceData(
      topups: topups ?? this.topups,
      pricing: pricing ?? this.pricing,
      commission: commission ?? this.commission,
    );
  }
}
