import 'package:dio/dio.dart';
import '../../../../shared/widgets/osm_map.dart';
import '../domain/models/address_result.dart';
import '../domain/repositories/address_repository.dart';

class OsmAddressRepository implements AddressRepository {
  final Dio _dio;

  OsmAddressRepository()
      : _dio = Dio(BaseOptions(
          baseUrl: 'https://nominatim.openstreetmap.org',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'User-Agent': OsmMap.userAgentPackageName,
            'Accept-Language': 'ru',
          },
        ));

  static const _astanaViewbox = '70.95,51.45,72.25,50.75';

  @override
  Future<List<AddressResult>> search(String query) async {
    if (query.trim().isEmpty) return const [];

    final response = await _dio.get<List<dynamic>>(
      '/search',
      queryParameters: {
        'q': _normalizeQuery(query),
        'format': 'jsonv2',
        'limit': 10,
        'countrycodes': 'kz',
        'viewbox': _astanaViewbox,
        'bounded': 1,
        'addressdetails': 1,
        'accept-language': 'ru',
      },
    );

    final seen = <String>{};
    final items = response.data ?? const [];
    
    return items
        .whereType<Map<String, dynamic>>()
        .map((json) => _mapToAddressResult(json))
        .where((item) => item.address.isNotEmpty)
        .where((item) => seen.add(item.address.toLowerCase()))
        .toList();
  }

  @override
  Future<AddressResult> reverse(double lat, double lng) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/reverse',
      queryParameters: {
        'lat': lat,
        'lon': lng,
        'format': 'jsonv2',
        'addressdetails': 1,
        'accept-language': 'ru',
      },
    );

    final data = response.data ?? {};
    final addressMap = data['address'] as Map<String, dynamic>? ?? {};
    final placeName = _placeName(data, addressMap);
    final formattedAddress = _buildShortAddress(addressMap, placeName: placeName) ??
        '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';

    return AddressResult(
      address: formattedAddress,
      lat: lat,
      lng: lng,
      source: 'openstreetmap',
    );
  }

  static String _normalizeQuery(String query) {
    final trimmed = query.trim();
    final lower = trimmed.toLowerCase();
    if (lower.contains('астана') || lower.contains('алматы')) {
      return trimmed;
    }
    return 'Казахстан, $trimmed';
  }

  AddressResult _mapToAddressResult(Map<String, dynamic> json) {
    final addressMap = json['address'] as Map<String, dynamic>? ?? {};
    final placeName = _placeName(json, addressMap);
    final lat = double.tryParse(json['lat']?.toString() ?? '') ?? 0;
    final lng = double.tryParse(json['lon']?.toString() ?? '') ?? 0;
    
    final formattedAddress = _buildShortAddress(addressMap, placeName: placeName) ?? 
        json['display_name']?.toString() ?? '';

    return AddressResult(
      address: formattedAddress,
      lat: lat,
      lng: lng,
      source: 'openstreetmap',
    );
  }

  String? _buildShortAddress(Map<String, dynamic> address, {String? placeName}) {
    final city = _cityFromAddress(address);
    final road = _stringValue(address, ['road', 'pedestrian', 'street']);
    final houseNumber = _stringValue(address, ['house_number']);

    final street = road == null ? null : houseNumber == null ? road : '$road $houseNumber';
    final parts = <String>[city];

    if (placeName != null && placeName.toLowerCase() != city.toLowerCase()) {
      parts.add(placeName);
    }
    if (street != null) parts.add(street);

    return parts.join(', ');
  }

  String _cityFromAddress(Map<String, dynamic> address) {
    return _stringValue(address, ['city', 'town', 'village', 'state']) ?? 'Казахстан';
  }

  String? _stringValue(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  String? _placeName(Map<String, dynamic> json, Map<String, dynamic> address) {
    return _stringValue(json, ['name']) ?? _stringValue(address, ['amenity', 'building', 'shop']);
  }
}
