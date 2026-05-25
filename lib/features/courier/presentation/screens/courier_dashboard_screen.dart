import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import 'package:citycargo_mobile/gen_l10n/app_localizations.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/orders/presentation/providers/orders_provider.dart';
import '../../../../shared/models/order_status.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/order_card.dart';
import '../providers/courier_provider.dart';

class CourierDashboardScreen extends ConsumerStatefulWidget {
  const CourierDashboardScreen({super.key});

  @override
  ConsumerState<CourierDashboardScreen> createState() =>
      _CourierDashboardScreenState();
}

class _CourierDashboardScreenState
    extends ConsumerState<CourierDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(courierOrdersProvider.notifier).load();
      ref.read(courierProvider.notifier).loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final user = ref.watch(authProvider).user;
    final courierState = ref.watch(courierProvider);
    final ordersState = ref.watch(courierOrdersProvider);

    final active = ordersState.orders
        .where((o) =>
            OrderStatusMapper.isAssigned(o.status) ||
            OrderStatusMapper.isInProgress(o.status))
        .toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(courierOrdersProvider.notifier).load(refresh: true);
            await ref.read(courierProvider.notifier).loadProfile();
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _Header(
                  name: user?.fullName ?? '',
                  isOnline: courierState.isOnline,
                  onToggle: (v) =>
                      ref.read(courierProvider.notifier).toggleOnline(v),
                ),
              ),
              if (active.isNotEmpty)
                SliverToBoxAdapter(
                  child: _ActiveBanner(
                    number: active.first.number,
                    status: active.first.status,
                  ),
                ),
              SliverToBoxAdapter(
                child: _StatsRow(profile: courierState.profile),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    l10n.availableOrders,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              if (ordersState.isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.courier),
                  ),
                )
              else if (ordersState.error != null)
                SliverFillRemaining(
                  child: AppErrorWidget(message: ordersState.error!),
                )
              else if (ordersState.orders.isEmpty)
                SliverFillRemaining(
                  child: EmptyStateWidget(
                    title: l10n.noAvailableOrders,
                    subtitle: l10n.goOnlineHint,
                    icon: Icons.inbox_outlined,
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => OrderCard(
                      order: ordersState.orders[i],
                      onTap: () {
                        final order = ordersState.orders[i];
                        if (order.number.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.errorNoOrderNumber),
                            ),
                          );
                          return;
                        }
                        context.push(
                          '/courier/orders/${Uri.encodeComponent(order.number)}',
                        );
                      },
                    ),
                    childCount: ordersState.orders.length,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String name;
  final bool isOnline;
  final void Function(bool) onToggle;

  const _Header({
    required this.name,
    required this.isOnline,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.cardColor,
      child: Row(children: [
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              l10n.helloGreeting(name.split(' ').first),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              isOnline ? l10n.youAreOnline : l10n.youAreOffline,
              style: TextStyle(
                color: isOnline ? AppColors.success : theme.hintColor,
              ),
            ),
          ]),
        ),
        Switch(
          value: isOnline,
          onChanged: onToggle,
          activeThumbColor: AppColors.success,
          activeTrackColor: AppColors.successLight,
        ),
      ]),
    );
  }
}

class _ActiveBanner extends StatelessWidget {
  final String number;
  final String status;

  const _ActiveBanner({
    required this.number,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        if (number.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.errorNoOrderNumber),
            ),
          );
          return;
        }
        context.push('/courier/orders/${Uri.encodeComponent(number)}');
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? AppColors.courier.withValues(alpha: 0.1)
              : AppColors.courierLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(children: [
          const Icon(Icons.delivery_dining, color: AppColors.courier),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.activeOrderLabel,
                  style: const TextStyle(
                    color: AppColors.courier,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  number,
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios,
              size: 14, color: AppColors.courier),
        ]),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final dynamic profile;
  const _StatsRow({this.profile});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: () => context.push('/courier/statistics'),
        child: Row(children: [
          _StatCard(
            label: l10n.today,
            value: '${profile?.ordersToday ?? 0}',
            icon: Icons.assignment_turned_in_outlined,
            color: AppColors.courier,
          ),
          const SizedBox(width: 12),
          _StatCard(
            label: l10n.earned,
            value: profile?.earningsTodayFormatted ?? '₸0',
            icon: Icons.account_balance_wallet_outlined,
            color: AppColors.success,
          ),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18, color: color)),
            Text(label,
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 12,
                )),
          ]),
        ]),
      ),
    );
  }
}
