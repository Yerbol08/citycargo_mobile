import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../shared/models/order_status.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/order_card.dart';
import '../../../../shared/widgets/skeleton_order_card.dart';
import 'package:citycargo_mobile/gen_l10n/app_localizations.dart';
import '../providers/orders_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool refresh = false}) {
    return ref.read(ordersProvider.notifier).load(refresh: refresh);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final state = ref.watch(ordersProvider);
    final active = state.orders
        .where((o) => OrderStatusMapper.info(o.status).isActive)
        .toList();
    final recent = state.orders.take(6).toList();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _load(refresh: true),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _Header(
                  name: user?.fullName ?? '',
                  activeCount: active.length,
                  totalCount: state.orders.length,
                ),
              ),
              if (active.isNotEmpty)
                SliverToBoxAdapter(
                  child: _ActiveBanner(number: active.first.number),
                ),
              SliverToBoxAdapter(
                child: _SectionTitle(
                  title: AppLocalizations.of(context)!.recentOrders,
                  actionLabel: AppLocalizations.of(context)!.all,
                  onAction: () => context.push('/orders'),
                ),
              ),
              if (state.isLoading)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => const SkeletonOrderCard(),
                    childCount: 3,
                  ),
                )
              else if (state.error != null)
                SliverFillRemaining(
                  child: AppErrorWidget(message: state.error!, onRetry: _load),
                )
              else if (state.orders.isEmpty)
                SliverFillRemaining(
                  child: EmptyStateWidget(
                    title: AppLocalizations.of(context)!.noOrdersTitle,
                    subtitle: AppLocalizations.of(context)!.noOrdersSubtitle,
                    icon: Icons.local_shipping_outlined,
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final order = recent[i];
                      return OrderCard(
                        order: order,
                        onTap: () {
                          if (order.number.isEmpty) return;
                          context.push(
                            '/orders/${Uri.encodeComponent(order.number)}',
                          );
                        },
                      );
                    },
                    childCount: recent.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 88)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/orders/create'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          AppLocalizations.of(context)!.newOrderButton,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String name;
  final int activeCount;
  final int totalCount;

  const _Header({
    required this.name,
    required this.activeCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final firstName =
        name.trim().isEmpty ? l10n.defaultClientName : name.trim().split(' ').first;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(16),
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
          Text(
            l10n.greeting(firstName),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.homeSubtitle,
            style: const TextStyle(color: Colors.white70, height: 1.3),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Metric(label: AppLocalizations.of(context)!.activeOrders, value: '$activeCount'),
              const SizedBox(width: 10),
              _Metric(label: AppLocalizations.of(context)!.totalOrders, value: '$totalCount'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(label, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class _ActiveBanner extends StatelessWidget {
  final String number;

  const _ActiveBanner({required this.number});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? AppColors.primary.withValues(alpha: 0.1)
        : AppColors.primaryLight;
    final borderColor = isDark
        ? AppColors.primary.withValues(alpha: 0.3)
        : AppColors.primary.withValues(alpha: 0.18);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: InkWell(
        onTap: number.isEmpty
            ? null
            : () => context.push('/orders/${Uri.encodeComponent(number)}'),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              const Icon(Icons.near_me_outlined, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.activeOrderLabel,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      number,
                      style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  const _SectionTitle({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
          TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
