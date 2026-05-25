import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../domain/models/wallet_model.dart';
import '../providers/wallet_provider.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen>
    with SingleTickerProviderStateMixin {
  static final _kaspiQrUri = Uri.parse('https://kaspi.kz/pay');

  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => ref.read(walletProvider.notifier).load());
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(walletProvider);
    final isCourier = ref.watch(authProvider).user?.isCourier ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Кошелек')),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : state.error != null && state.wallet == null
              ? Center(child: Text(state.error!))
              : RefreshIndicator(
                  onRefresh: () => ref.read(walletProvider.notifier).load(),
                  child: Column(
                    children: [
                      _BalanceCard(
                        wallet: state.wallet ??
                            const WalletModel(
                              id: '',
                              balanceMinor: 0,
                              currency: 'KZT',
                            ),
                        isCourier: isCourier,
                        onAction: isCourier ? null : _showTopUp,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusLg),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          child: TabBar(
                            controller: _tab,
                            labelColor: AppColors.primary,
                            unselectedLabelColor: AppColors.textSecondary,
                            indicatorSize: TabBarIndicatorSize.tab,
                            indicator: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusMd),
                            ),
                            dividerColor: Colors.transparent,
                            tabs: const [
                              Tab(text: 'Начисления'),
                              Tab(text: 'Списания'),
                              Tab(text: 'Пополнения'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: TabBarView(
                          controller: _tab,
                          children: [
                            _TxList(
                              txs: state.transactions
                                  .where((t) => t.isCredit)
                                  .toList(),
                            ),
                            _TxList(
                              txs: state.transactions
                                  .where((t) => !t.isCredit)
                                  .toList(),
                            ),
                            _TopUpList(topUps: state.topUps),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  void _showTopUp() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (_) => _TopUpSheet(
        onTopUp: (amount, comment) async {
          Navigator.pop(context);
          try {
            await ref.read(walletProvider.notifier).topUp(
                  amount * 100,
                  comment: comment,
                );
            if (!mounted) return;
            await _showKaspiDialog(amount);
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  userErrorMessage(
                    e,
                    fallback: 'Не удалось создать заявку на пополнение',
                  ),
                ),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _showKaspiDialog(int amount) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.qr_code_2, color: AppColors.primary, size: 46),
        title: const Text('Заявка отправлена'),
        content: Text(
          'Сумма: $amount KZT\n\nПерейдите к оплате через Kaspi QR. Модератор подтвердит пополнение после проверки оплаты.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Позже'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await launchUrl(_kaspiQrUri,
                  mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Открыть Kaspi QR'),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final WalletModel wallet;
  final bool isCourier;
  final VoidCallback? onAction;

  const _BalanceCard({
    required this.wallet,
    required this.isCourier,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.primary, const Color(0xFF107A4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Доступный баланс',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  wallet.currency,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            wallet.balanceFormatted,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAction,
              icon: Icon(isCourier ? Icons.account_balance_wallet : Icons.add),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor:
                    isCourier ? AppColors.success : AppColors.primary,
              ),
              label: Text(isCourier ? 'Выплаты' : 'Запросить пополнение'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TxList extends StatelessWidget {
  final List<TransactionModel> txs;
  const _TxList({required this.txs});

  @override
  Widget build(BuildContext context) {
    if (txs.isEmpty) {
      return const Center(
        child: Text(
          'Операций пока нет',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: txs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) => _TxTile(tx: txs[i]),
    );
  }
}

class _TxTile extends StatelessWidget {
  final TransactionModel tx;
  const _TxTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    return _ListSurface(
      leading: Icon(
        tx.isCredit ? Icons.arrow_downward : Icons.arrow_upward,
        color: tx.isCredit ? AppColors.success : AppColors.danger,
        size: 20,
      ),
      title: tx.description.isEmpty ? tx.type : tx.description,
      subtitle: DateFormatter.formatDateTime(tx.createdAt),
      trailing: '${tx.isCredit ? '+' : '-'}${tx.amountFormatted}',
      trailingColor: tx.isCredit ? AppColors.success : AppColors.danger,
    );
  }
}

class _TopUpSheet extends StatefulWidget {
  final void Function(int amount, String comment) onTopUp;
  const _TopUpSheet({required this.onTopUp});

  @override
  State<_TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<_TopUpSheet> {
  final _ctrl = TextEditingController();
  final _commentCtrl = TextEditingController(text: 'Пополнение через Kaspi');

  @override
  void dispose() {
    _ctrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        24,
        16,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Пополнение счета',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'После отправки заявки вы перейдете на Kaspi QR. Модератор подтвердит пополнение после проверки оплаты.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Сумма пополнения, ₸',
              prefixText: '₸ ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentCtrl,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Комментарий',
              hintText: 'Например, пополнение через Kaspi',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.qr_code_2),
            onPressed: () {
              final val = int.tryParse(_ctrl.text);
              if (val != null && val > 0) {
                widget.onTopUp(val, _commentCtrl.text.trim());
              }
            },
            label: const Text('Перейти к оплате и отправить заявку'),
          ),
        ],
      ),
    );
  }
}

class _TopUpList extends StatelessWidget {
  final List<TopUpModel> topUps;
  const _TopUpList({required this.topUps});

  @override
  Widget build(BuildContext context) {
    if (topUps.isEmpty) {
      return const Center(
        child: Text(
          'Заявок на пополнение пока нет',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: topUps.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _TopUpTile(topUp: topUps[index]),
    );
  }
}

class _TopUpTile extends StatelessWidget {
  final TopUpModel topUp;
  const _TopUpTile({required this.topUp});

  @override
  Widget build(BuildContext context) {
    final color = switch (topUp.status) {
      'confirmed' || 'approved' => AppColors.success,
      'rejected' || 'cancelled' => AppColors.danger,
      _ => AppColors.primary,
    };
    return _ListSurface(
      leading: Icon(Icons.payments_outlined, color: color, size: 20),
      title: topUp.amountFormatted,
      subtitle: [
        _topUpStatusLabel(topUp.status),
        if (topUp.comment.isNotEmpty) topUp.comment,
        if (topUp.reason != null && topUp.reason!.isNotEmpty) topUp.reason!,
        if (topUp.createdAt != null)
          DateFormatter.formatDateTime(topUp.createdAt!),
      ].join('\n'),
    );
  }

  String _topUpStatusLabel(String status) => switch (status) {
        'pending' => 'Ожидает проверки',
        'confirmed' || 'approved' => 'Подтверждено',
        'rejected' => 'Отклонено',
        'cancelled' => 'Отменено',
        _ => status.isEmpty ? 'Без статуса' : status,
      };
}

class _ListSurface extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final String? trailing;
  final Color? trailingColor;

  const _ListSurface({
    required this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.trailingColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: Center(child: leading),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            Text(
              trailing!,
              style: TextStyle(
                color: trailingColor ?? AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
