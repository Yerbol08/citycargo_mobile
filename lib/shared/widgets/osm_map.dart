import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import '../../app/theme.dart';

class OsmMap extends StatelessWidget {
  static const userAgentPackageName = 'kz.citycargo.citycargo_mobile';
  static const double _minZoom = 4;
  static const double _maxZoom = 18;

  final MapController? controller;
  final LatLng initialCenter;
  final double initialZoom;
  final LatLng? selectedPoint;
  final LatLng? courierPoint;
  final LatLng? deliveryPoint;
  final List<LatLng> routePoints;
  final ValueChanged<LatLng>? onTap;
  final VoidCallback? onMapReady;
  final void Function(MapCamera, bool)? onPositionChanged;
  final void Function(Object error)? onTileError;
  final bool isLoading;
  final String? errorMessage;
  final bool showZoomControls;
  final bool interactive;

  const OsmMap({
    super.key,
    this.controller,
    required this.initialCenter,
    this.initialZoom = 13,
    this.selectedPoint,
    this.courierPoint,
    this.deliveryPoint,
    this.routePoints = const [],
    this.onTap,
    this.onMapReady,
    this.onPositionChanged,
    this.onTileError,
    this.isLoading = false,
    this.errorMessage,
    this.showZoomControls = true,
    this.interactive = true,
  });

  @override
  Widget build(BuildContext context) {
    final mapController = controller ?? MapController();
    final markers = <Marker>[
      if (courierPoint != null)
        _pinMarker(
          point: courierPoint!,
          color: AppColors.textPrimary,
          icon: Icons.local_shipping_outlined,
          label: '\u041a\u0443\u0440\u044c\u0435\u0440',
        ),
      if (deliveryPoint != null)
        _pinMarker(
          point: deliveryPoint!,
          color: AppColors.info,
          icon: Icons.flag_outlined,
          label: '\u041f\u043e\u043b\u0443\u0447\u0430\u0442\u0435\u043b\u044c',
        ),
      if (selectedPoint != null)
        _pinMarker(
          point: selectedPoint!,
          color: AppColors.success,
          icon: Icons.inventory_2_outlined,
          label:
              '\u041e\u0442\u043f\u0440\u0430\u0432\u0438\u0442\u0435\u043b\u044c',
        ),
    ];

    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: initialZoom.clamp(_minZoom, _maxZoom).toDouble(),
                minZoom: _minZoom,
                maxZoom: _maxZoom,
                interactionOptions: InteractionOptions(
                  flags:
                      interactive ? InteractiveFlag.all : InteractiveFlag.none,
                ),
                onMapReady: () {
                  if (kDebugMode) debugPrint('CityCargoOSM: map initialized');
                  onMapReady?.call();
                },
                onPositionChanged: onPositionChanged,
                onTap: onTap == null
                    ? null
                    : (_, point) {
                        if (kDebugMode) {
                          debugPrint(
                            'CityCargoOSM: selected ${point.latitude}, ${point.longitude}',
                          );
                        }
                        onTap?.call(point);
                      },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: userAgentPackageName,
                  errorTileCallback: (_, error, __) {
                    if (kDebugMode) {
                      debugPrint('CityCargoOSM: tile loading failed: $error');
                    }
                    onTileError?.call(error);
                  },
                ),
                if (routePoints.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routePoints,
                        color: AppColors.primary,
                        strokeWidth: 5,
                      ),
                    ],
                  ),
                if (markers.isNotEmpty)
                  MarkerClusterLayerWidget(
                    options: MarkerClusterLayerOptions(
                      maxClusterRadius: 45,
                      size: const Size(40, 40),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(50),
                      maxZoom: 15,
                      markers: markers,
                      builder: (context, markers) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: AppColors.primary,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 8,
                              )
                            ],
                          ),
                          child: Center(
                            child: Text(
                              markers.length.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          if (showZoomControls && interactive)
            Positioned(
              right: 12,
              bottom: 18,
              child: _ZoomControls(controller: mapController),
            ),
          if (isLoading)
            const Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: _MapStatusBanner(
                message:
                    '\u0417\u0430\u0433\u0440\u0443\u0436\u0430\u0435\u043c \u043a\u0430\u0440\u0442\u0443...',
                isError: false,
              ),
            ),
          if (errorMessage != null && errorMessage!.isNotEmpty)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: _MapStatusBanner(
                message: errorMessage!,
                isError: true,
              ),
            ),
        ],
      ),
    );
  }

  static Marker _pinMarker({
    required LatLng point,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Marker(
      point: point,
      width: 84,
      height: 90,
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: 84,
        height: 90,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 72),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            _MapPin(color: color, icon: icon),
          ],
        ),
      ),
    );
  }
}

class _ZoomControls extends StatelessWidget {
  final MapController controller;

  const _ZoomControls({required this.controller});

  void _zoomBy(double delta) {
    try {
      final camera = controller.camera;
      if (delta < 0 && camera.zoom <= OsmMap._minZoom + 0.01) return;
      if (delta > 0 && camera.zoom >= OsmMap._maxZoom - 0.01) return;
      final nextZoom = (camera.zoom + delta)
          .clamp(OsmMap._minZoom, OsmMap._maxZoom)
          .toDouble();
      controller.move(camera.center, nextZoom);
      if (kDebugMode) debugPrint('CityCargoOSM: zoom changed to $nextZoom');
    } catch (error) {
      if (kDebugMode) {
        debugPrint('CityCargoOSM: zoom control ignored before ready: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 44,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ZoomButton(
              icon: Icons.add,
              tooltip: '\u0423\u0432\u0435\u043b\u0438\u0447\u0438\u0442\u044c',
              onPressed: () => _zoomBy(1),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.border),
            _ZoomButton(
              icon: Icons.remove,
              tooltip: '\u0423\u043c\u0435\u043d\u044c\u0448\u0438\u0442\u044c',
              onPressed: () => _zoomBy(-1),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ZoomButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: AppColors.textPrimary, size: 24),
        ),
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _MapPin({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 54,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 26,
            child: Transform.rotate(
              angle: 0.785398,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}

class _MapStatusBanner extends StatelessWidget {
  final String message;
  final bool isError;

  const _MapStatusBanner({
    required this.message,
    required this.isError,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            isError ? AppColors.danger : Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }
}
