import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../core/maps/osm_route_service.dart';
import '../../features/orders/domain/models/order_model.dart';
import 'package:citycargo_mobile/gen_l10n/app_localizations.dart';
import '../models/order_status.dart';
import 'osm_map.dart';

class OrderMiniMapCard extends StatefulWidget {
  final OrderModel order;
  final bool interactive;

  const OrderMiniMapCard({
    super.key,
    required this.order,
    this.interactive = false,
  });

  @override
  State<OrderMiniMapCard> createState() => _OrderMiniMapCardState();
}

class _OrderMiniMapCardState extends State<OrderMiniMapCard> {
  late Future<List<LatLng>> _routeFuture;

  @override
  void initState() {
    super.initState();
    _routeFuture = _loadRoute();
  }

  @override
  void didUpdateWidget(covariant OrderMiniMapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.id != widget.order.id ||
        oldWidget.order.senderLat != widget.order.senderLat ||
        oldWidget.order.senderLng != widget.order.senderLng ||
        oldWidget.order.recipientLat != widget.order.recipientLat ||
        oldWidget.order.recipientLng != widget.order.recipientLng) {
      _routeFuture = _loadRoute();
    }
  }

  Future<List<LatLng>> _loadRoute() async {
    final sender = LatLng(widget.order.senderLat, widget.order.senderLng);
    final recipient =
        LatLng(widget.order.recipientLat, widget.order.recipientLng);
    try {
      final points = await OsmRouteService().loadDrivingRoute(
        start: sender,
        end: recipient,
      );
      if (points.length >= 2) return points;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('CityCargoOSM: route preview fallback: $error');
      }
    }
    return [sender, recipient];
  }

  @override
  Widget build(BuildContext context) {
    final sender = LatLng(widget.order.senderLat, widget.order.senderLng);
    final recipient =
        LatLng(widget.order.recipientLat, widget.order.recipientLng);
    final center = LatLng(
      (widget.order.senderLat + widget.order.recipientLat) / 2,
      (widget.order.senderLng + widget.order.recipientLng) / 2,
    );
    final l10n = AppLocalizations.of(context)!;

    return _ToolCard(
      title: l10n.routeMap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: SizedBox(
          height: 180,
          child: FutureBuilder<List<LatLng>>(
            future: _routeFuture,
            builder: (context, snapshot) {
              final routePoints = snapshot.data ?? [sender, recipient];
              final routeFailed = snapshot.hasError;
              return OsmMap(
                initialCenter: center,
                initialZoom: 11,
                selectedPoint: sender,
                deliveryPoint: recipient,
                routePoints: routePoints,
                showZoomControls: false,
                interactive: widget.interactive,
                errorMessage:
                    routeFailed ? l10n.routeUnavailable : null,
              );
            },
          ),
        ),
      ),
    );
  }
}

class OrderTimelineCard extends StatelessWidget {
  final String status;

  const OrderTimelineCard({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final steps = [
      _TimelineStep('created', l10n.statusCreated, Icons.add_circle_outline),
      _TimelineStep(
        'assigned_to_courier',
        l10n.statusAssigned,
        Icons.person_pin_circle_outlined,
      ),
      _TimelineStep(
        'courier_arrived_sender',
        l10n.statusArrivedSender,
        Icons.place_outlined,
      ),
      _TimelineStep(
        'picked_up',
        l10n.statusPickedUp,
        Icons.inventory_2_outlined,
      ),
      _TimelineStep(
        'courier_arrived_recipient',
        l10n.statusArrivedRecipient,
        Icons.flag_outlined,
      ),
      _TimelineStep('delivered', l10n.statusDelivered, Icons.check_circle_outline),
    ];

    final currentIndex = _statusIndex(status, steps);

    return _ToolCard(
      title: l10n.orderStatus,
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            _TimelineRow(
              step: steps[i],
              isDone: i <= currentIndex,
              isCurrent: i == currentIndex,
              isLast: i == steps.length - 1,
            ),
        ],
      ),
    );
  }

  int _statusIndex(String value, List<_TimelineStep> steps) {
    final info = OrderStatusMapper.info(value);
    if (info.code == 'completed') return steps.length - 1;
    if (info.code == 'delivery_in_progress') {
      return steps.indexWhere(
        (step) => step.status == 'courier_arrived_recipient',
      );
    }
    final index = steps.indexWhere((step) => step.status == info.code);
    return index < 0 ? 0 : index;
  }
}

class OrderNavigationActions extends StatelessWidget {
  final OrderModel order;
  final bool includeSender;
  final bool includeRecipient;

  const OrderNavigationActions({
    super.key,
    required this.order,
    this.includeSender = true,
    this.includeRecipient = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        if (includeSender)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _openNavigation(
                lat: order.senderLat,
                lng: order.senderLng,
                label: order.senderAddress,
              ),
              icon: const Icon(Icons.navigation_outlined),
              label: Text(l10n.toSender),
            ),
          ),
        if (includeSender && includeRecipient) const SizedBox(width: 10),
        if (includeRecipient)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _openNavigation(
                lat: order.recipientLat,
                lng: order.recipientLng,
                label: order.recipientAddress,
              ),
              icon: const Icon(Icons.flag_outlined),
              label: Text(l10n.toRecipient),
            ),
          ),
      ],
    );
  }

  Future<void> _openNavigation({
    required double lat,
    required double lng,
    required String label,
  }) async {
    final encodedLabel =
        Uri.encodeComponent(label.isEmpty ? 'CityCargo' : label);
    final uri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($encodedLabel)');
    final webUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ToolCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ToolCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final _TimelineStep step;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;

  const _TimelineRow({
    required this.step,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDone ? AppColors.primary : Theme.of(context).dividerColor;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: isDone
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Theme.of(context).scaffoldBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(step.icon, color: color, size: 18),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 22,
                color: isDone ? AppColors.primary : Theme.of(context).dividerColor,
              ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              step.label,
              style: TextStyle(
                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                color: isDone 
                    ? Theme.of(context).textTheme.bodyLarge?.color 
                    : Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineStep {
  final String status;
  final String label;
  final IconData icon;

  const _TimelineStep(this.status, this.label, this.icon);
}
