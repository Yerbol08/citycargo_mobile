import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../shared/models/api_response_model.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_cards.dart';

class AdminChatsScreen extends ConsumerStatefulWidget {
  const AdminChatsScreen({super.key});

  @override
  ConsumerState<AdminChatsScreen> createState() => _AdminChatsScreenState();
}

class _AdminChatsScreenState extends ConsumerState<AdminChatsScreen> {
  late Future<List<OrderSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<OrderSummary>> _load() {
    return ref.read(adminRepositoryProvider).getOrders();
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  void _openChat(OrderSummary order) {
    final id = Uri.encodeComponent(order.id);
    final title = Uri.encodeComponent(order.number);
    context.push('/chat/$id?title=$title');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<OrderSummary>>(
      future: _future,
      builder: (context, snap) {
        final orders = snap.data ?? const <OrderSummary>[];
        return AdminListScaffold(
          title: 'Чаты заказов',
          isLoading: snap.connectionState == ConnectionState.waiting,
          error: snap.hasError
              ? userErrorMessage(
                  snap.error!,
                  fallback: 'Не удалось загрузить чаты',
                )
              : null,
          onRefresh: _refresh,
          header: const Text(
            'Выберите заказ. Если чата ещё нет, он будет создан автоматически.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          children: [
            for (final order in orders)
              AdminDataCard(
                title: order.number,
                subtitle: '${order.senderAddress}\n${order.recipientAddress}',
                trailing: order.status,
                icon: Icons.chat_outlined,
                color: AppColors.primary,
                onTap: () => _openChat(order),
                actions: [
                  FilledButton.icon(
                    onPressed: () => _openChat(order),
                    icon: const Icon(Icons.forum_outlined, size: 18),
                    label: const Text('Открыть чат'),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}
