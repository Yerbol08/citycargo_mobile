import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../app/theme.dart';
import '../../../../core/maps/osm_route_service.dart';
import '../../../../shared/widgets/osm_map.dart';

class MapDebugScreen extends StatefulWidget {
  const MapDebugScreen({super.key});

  @override
  State<MapDebugScreen> createState() => _MapDebugScreenState();
}

class _MapDebugScreenState extends State<MapDebugScreen> {
  static const _astana = LatLng(51.1605, 71.4704);
  static const _deliveryPoint = LatLng(51.1282, 71.4304);

  final _mapCtrl = MapController();
  final _routeService = OsmRouteService();
  List<LatLng> _routePoints = const [];
  LatLng _selectedPoint = _deliveryPoint;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final route = await _routeService.loadDrivingRoute(
        start: _astana,
        end: _selectedPoint,
      );
      if (!mounted) return;
      setState(() => _routePoints = route);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Не удалось загрузить маршрут OSRM');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OSM Map Debug')),
      body: Stack(
        children: [
          Positioned.fill(
            child: OsmMap(
              controller: _mapCtrl,
              initialCenter: _astana,
              initialZoom: 12,
              courierPoint: _astana,
              deliveryPoint: _selectedPoint,
              selectedPoint: _selectedPoint,
              routePoints: _routePoints,
              isLoading: _isLoading,
              errorMessage: _error,
              onMapReady: () {
                debugPrint('CityCargoOSM: debug map initialized');
                setState(() => _isLoading = false);
              },
              onTap: (point) {
                setState(() => _selectedPoint = point);
                _loadRoute();
              },
              onTileError: (_) {
                setState(() => _error = 'Не удалось загрузить тайлы OSM');
              },
            ),
          ),
          const Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Card(
              elevation: 0,
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Expected: OpenStreetMap tiles around Astana, courier marker, delivery marker and route line. '
                  'No Google API key or Google Play Services required.',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
