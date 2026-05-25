import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/error_messages.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_cards.dart';

class AdminCouriersScreen extends ConsumerStatefulWidget {
  const AdminCouriersScreen({super.key});

  @override
  ConsumerState<AdminCouriersScreen> createState() =>
      _AdminCouriersScreenState();
}

class _AdminCouriersScreenState extends ConsumerState<AdminCouriersScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() {
    return ref.read(adminRepositoryProvider).getCouriers(status: 'pending');
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _approve(Map<String, dynamic> courier) async {
    final id = _id(courier);
    if (!_hasId(id)) return _showSnack('Не найден ID заявки курьера');
    try {
      await ref.read(adminRepositoryProvider).approveCourier(
            id,
            comment: 'Одобрено оператором',
          );
      _showSnack('Заявка курьера одобрена');
      _refresh();
    } catch (e) {
      _showSnack(
        userErrorMessage(e, fallback: 'Не удалось одобрить курьера'),
        error: true,
      );
    }
  }

  Future<void> _reject(Map<String, dynamic> courier) async {
    final id = _id(courier);
    if (!_hasId(id)) return _showSnack('Не найден ID заявки курьера');
    final reason = await _askReason('Причина отклонения');
    if (reason == null) return;
    try {
      await ref.read(adminRepositoryProvider).rejectCourier(
            id,
            reason: reason,
            comment: reason,
          );
      _showSnack('Заявка курьера отклонена');
      _refresh();
    } catch (e) {
      _showSnack(
        userErrorMessage(e, fallback: 'Не удалось отклонить курьера'),
        error: true,
      );
    }
  }

  Future<void> _showHistory(Map<String, dynamic> courier) async {
    final id = _id(courier);
    if (!_hasId(id)) return _showSnack('Не найден ID заявки курьера');
    try {
      final history = await ref.read(adminRepositoryProvider).getCourierHistory(
            id,
          );
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          builder: (context, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'История курьера',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              if (history.isEmpty)
                const Text(
                  'История пока не найдена',
                  style: TextStyle(color: AppColors.textSecondary),
                )
              else
                for (final item in history)
                  AdminDataCard(
                    title: _text(item, ['action', 'status', 'event', 'type']),
                    subtitle: _compact(item),
                    icon: Icons.history,
                    color: AppColors.primary,
                  ),
            ],
          ),
        ),
      );
    } catch (e) {
      _showSnack(
        userErrorMessage(e, fallback: 'Не удалось загрузить историю'),
        error: true,
      );
    }
  }

  Future<String?> _askReason(String title) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Причина',
            hintText: 'Например: некорректные данные автомобиля',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) Navigator.pop(context, text);
            },
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snap) {
        final couriers = snap.data ?? const <Map<String, dynamic>>[];
        return AdminListScaffold(
          title: 'Заявки курьеров',
          isLoading: snap.connectionState == ConnectionState.waiting,
          error: snap.hasError
              ? userErrorMessage(
                  snap.error!,
                  fallback: 'Не удалось загрузить заявки курьеров',
                )
              : null,
          onRefresh: _refresh,
          children: [
            for (final courier in couriers)
              AdminDataCard(
                title: _text(courier, ['full_name', 'name', 'phone']),
                subtitle: [
                  _text(courier, ['phone']),
                  _text(courier, ['transport_type']),
                  _text(courier, ['vehicle_number']),
                  _text(courier, ['comment']),
                ].where((v) => v != '-').join('\n'),
                trailing: _text(courier, ['status']),
                icon: Icons.delivery_dining,
                color: AppColors.courier,
                actions: [
                  ElevatedButton.icon(
                    onPressed: () => _approve(courier),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Одобрить'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _reject(courier),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Отклонить'),
                  ),
                  TextButton.icon(
                    onPressed: () => _showHistory(courier),
                    icon: const Icon(Icons.history, size: 18),
                    label: const Text('История'),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  bool _hasId(String value) => value.trim().isNotEmpty && value != '-';

  String _id(Map<String, dynamic> json) =>
      _text(json, ['profile_id', 'courier_profile_id', 'id']);

  String _text(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return '-';
  }

  String _compact(Map<String, dynamic> json) {
    final entries = json.entries
        .where((entry) => entry.value != null && entry.value.toString() != '')
        .take(8)
        .map((entry) => '${entry.key}: ${entry.value}');
    return entries.join('\n');
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
