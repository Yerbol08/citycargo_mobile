import 'package:flutter/material.dart';
import '../../app/theme.dart';
import 'package:citycargo_mobile/gen_l10n/app_localizations.dart';
import '../models/api_response_model.dart';
import 'app_badge.dart';
import 'bouncing_widget.dart';

class OrderCard extends StatelessWidget {
  final OrderSummary order;
  final VoidCallback? onTap;

  const OrderCard({super.key, required this.order, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Hero(
        tag: order.number.isEmpty ? 'order-${order.hashCode}' : 'order-${order.number}',
        child: BouncingWidget(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.number.isEmpty ? l10n.orderLabel : order.number,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: Theme.of(context).textTheme.titleSmall?.color,
                              letterSpacing: -0.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.priceFormatted,
                            style: TextStyle(
                              color: Theme.of(context).textTheme.titleLarge?.color,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppBadge.orderStatus(order.status),
                  ],
                ),
                const SizedBox(height: 14),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        children: [
                          const _RouteDot(color: AppColors.primary),
                          Expanded(
                            child: Container(
                              width: 1,
                              margin: const EdgeInsets.symmetric(vertical: 3),
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                          _RouteDot(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _AddressText(order.senderAddress),
                            const SizedBox(height: 10),
                            _AddressText(order.recipientAddress),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Center(
                        child: Icon(
                          Icons.chevron_right,
                          color: Theme.of(context).disabledColor,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RouteDot extends StatelessWidget {
  final Color color;
  const _RouteDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _AddressText extends StatelessWidget {
  final String address;
  const _AddressText(this.address);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Text(
      address.isEmpty ? l10n.addressNotSpecified : address,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 13,
        height: 1.25,
        color: Theme.of(context).textTheme.bodySmall?.color,
      ),
    );
  }
}
