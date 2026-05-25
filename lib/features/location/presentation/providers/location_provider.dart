import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/location_repository.dart';

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository(ref.watch(apiClientProvider));
});

class LocationState {
  final Position? lastPosition;
  final bool isTracking;
  final bool hasPermission;

  const LocationState({
    this.lastPosition,
    this.isTracking = false,
    this.hasPermission = false,
  });

  LocationState copyWith({
    Position? lastPosition,
    bool? isTracking,
    bool? hasPermission,
  }) =>
      LocationState(
        lastPosition: lastPosition ?? this.lastPosition,
        isTracking: isTracking ?? this.isTracking,
        hasPermission: hasPermission ?? this.hasPermission,
      );
}

// Sends GPS every 5s only while courier has an active order
class LocationNotifier extends StateNotifier<LocationState> {
  final LocationRepository _repo;
  final String _userId;
  Timer? _timer;

  LocationNotifier(this._repo, {required String userId})
      : _userId = userId,
        super(const LocationState());

  Future<void> startTracking() async {
    if (state.isTracking) return;
    final granted = await _repo.requestPermission();
    if (!granted) {
      state = state.copyWith(hasPermission: false);
      return;
    }
    state = state.copyWith(isTracking: true, hasPermission: true);
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _send());
  }

  void stopTracking() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(isTracking: false);
  }

  Future<void> _send() async {
    final pos = await _repo.getCurrentPosition();
    if (pos == null || !mounted) return;
    state = state.copyWith(lastPosition: pos);
    try {
      await _repo.sendLocation(pos, _userId);
    } catch (_) {
      // Silent — location is best-effort
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final locationProvider =
    StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  final userId = ref.read(authProvider).user?.id ?? '';
  return LocationNotifier(
    ref.watch(locationRepositoryProvider),
    userId: userId,
  );
});
