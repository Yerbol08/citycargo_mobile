import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/api/api_exception.dart';
import 'package:citycargo_mobile/gen_l10n/app_localizations.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../domain/models/create_order_params.dart';
import '../providers/orders_provider.dart';

class OrderPreviewScreen extends ConsumerStatefulWidget {
  final CreateOrderParams params;

  const OrderPreviewScreen({super.key, required this.params});

  @override
  ConsumerState<OrderPreviewScreen> createState() => _OrderPreviewScreenState();
}

class _OrderPreviewScreenState extends ConsumerState<OrderPreviewScreen> {
  bool _isLoading = false;

  Future<void> _confirm() async {
    setState(() => _isLoading = true);
    final theme = Theme.of(context);
    try {
      final order = await ref.read(ordersRepositoryProvider).createOrder(
            senderPhone: widget.params.senderPhone,
            senderAddress: widget.params.senderAddress,
            senderLat: widget.params.senderLat,
            senderLng: widget.params.senderLng,
            recipientPhone: widget.params.recipientPhone,
            recipientAddress: widget.params.recipientAddress,
            recipientLat: widget.params.recipientLat,
            recipientLng: widget.params.recipientLng,
            parcelCount: widget.params.parcelCount,
            comment: widget.params.comment,
          );
      
      if (!mounted) return;
      
      // Refresh list
      ref.read(ordersProvider.notifier).load();
      
      if (order.number.isNotEmpty) {
        context.go('/orders/${Uri.encodeComponent(order.number)}');
      } else {
        context.go('/orders');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.userMessage),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.orderPreview)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Section(
              title: l10n.route,
              child: _RouteSummary(params: widget.params),
            ),
            const SizedBox(height: 16),
            _Section(
              title: l10n.details,
              child: Column(
                children: [
                  _InfoRow(l10n.parcel, l10n.itemsCount(widget.params.parcelCount)),
                  if (widget.params.comment != null && widget.params.comment!.isNotEmpty)
                    _InfoRow(l10n.commentLabel, widget.params.comment!),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.orderCreationNotice,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            AppButton(
              label: l10n.confirmAndSend,
              onPressed: _isLoading ? null : _confirm,
              isLoading: _isLoading,
              icon: Icons.check_circle,
            ),
            const SizedBox(height: 12),
            AppButton(
              label: l10n.editData,
              outlined: true,
              onPressed: _isLoading ? null : () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: theme.textTheme.bodySmall?.color ?? AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(color: theme.dividerColor),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _RouteSummary extends StatelessWidget {
  final CreateOrderParams params;

  const _RouteSummary({required this.params});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      children: [
        _AddressBlock(
          label: l10n.fromLabel,
          address: params.senderAddress,
          phone: params.senderPhone,
          color: theme.colorScheme.primary,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(),
        ),
        _AddressBlock(
          label: l10n.toLabel,
          address: params.recipientAddress,
          phone: params.recipientPhone,
          color: theme.colorScheme.secondary,
        ),
      ],
    );
  }
}

class _AddressBlock extends StatelessWidget {
  final String label;
  final String address;
  final String phone;
  final Color color;

  const _AddressBlock({
    required this.label,
    required this.address,
    required this.phone,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.place, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                address,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 2),
              Text(
                phone,
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color ?? AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color ?? AppColors.textSecondary,
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
