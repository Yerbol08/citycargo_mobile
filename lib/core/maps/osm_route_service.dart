import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

class OsmRouteService {
  OsmRouteService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://router.project-osrm.org',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              headers: {
                'User-Agent': 'kz.citycargo.citycargo_mobile',
              },
            ));

  final Dio _dio;

  Future<List<LatLng>> loadDrivingRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    final path =
        '/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}';

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: {
          'overview': 'full',
          'geometries': 'geojson',
        },
      );

      final routes = response.data?['routes'] as List<dynamic>? ?? const [];
      if (routes.isEmpty) {
        throw const OsmRouteException('OSRM returned no routes');
      }

      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>? ?? const {};
      final coordinates = geometry['coordinates'] as List<dynamic>? ?? const [];

      final points = coordinates
          .whereType<List<dynamic>>()
          .where((pair) => pair.length >= 2)
          .map((pair) => LatLng(
                (pair[1] as num).toDouble(),
                (pair[0] as num).toDouble(),
              ))
          .toList(growable: false);

      debugPrint('CityCargoOSM: route loaded, points=${points.length}');
      return points;
    } catch (error) {
      debugPrint('CityCargoOSM: route loading failed: $error');
      if (error is OsmRouteException) rethrow;
      throw OsmRouteException(error.toString());
    }
  }
}

class OsmRouteException implements Exception {
  final String message;

  const OsmRouteException(this.message);

  @override
  String toString() => message;
}
