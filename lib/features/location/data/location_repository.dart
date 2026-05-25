import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/api/api_client.dart';

class LocationRepository {
  final ApiClient _client;

  LocationRepository(this._client);

  Future<bool> requestPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  Future<Position?> getCurrentPosition() async {
    final granted = await requestPermission();
    if (!granted) return null;
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> sendLocation(Position position, String userId) async {
    await _client.post('/api/v1/locations', data: {
      'user_id': userId,
      'latitude': position.latitude,
      'longitude': position.longitude,
    });
  }

  Stream<Position> trackPosition() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }
}
