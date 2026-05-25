import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../app/theme.dart';
import '../../../../core/maps/osm_route_service.dart';
import '../../../../shared/widgets/osm_map.dart';
import '../../domain/models/address_result.dart';
import '../../../../core/utils/debouncer.dart';
import '../providers/orders_provider.dart';

class AddressPickerScreen extends ConsumerStatefulWidget {
  const AddressPickerScreen({super.key});

  @override
  ConsumerState<AddressPickerScreen> createState() => _AddressPickerScreenState();
}

class _AddressPickerScreenState extends ConsumerState<AddressPickerScreen> {
  static const _astanaCenter = LatLng(51.1605, 71.4704);

  final _searchCtrl = TextEditingController();
  final _mapCtrl = MapController();
  final _routeService = OsmRouteService();
  final _searchDebouncer = Debouncer(milliseconds: 450);
  final _panDebouncer = Debouncer(milliseconds: 800);

  LatLng? _selectedPoint;
  LatLng? _currentLocation;
  List<LatLng> _routePoints = const [];
  List<AddressResult> _suggestions = const [];
  String _resolvedAddress = 'Астана';
  bool _ignoreSearchChanges = false;
  bool _isMapLoading = true;
  bool _isResolvingAddress = false;
  bool _isSearching = false;
  bool _isLocating = false;
  bool _isRouteLoading = false;
  bool _isPanning = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = _resolvedAddress;
    _searchCtrl.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _searchDebouncer.cancel();
    _panDebouncer.cancel();
    _searchCtrl.removeListener(_onSearchTextChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    if (_ignoreSearchChanges) return;

    _searchDebouncer.cancel();
    final query = _searchCtrl.text.trim();
    if (query.length < 3) {
      setState(() => _suggestions = const []);
      return;
    }

    _searchDebouncer.run(() {
      _searchAddress(query);
    });
  }

  Future<void> _searchAddress(String query) async {
    if (!mounted) return;
    setState(() => _isSearching = true);
    try {
      final suggestions = await ref.read(addressRepositoryProvider).search(query);
      if (!mounted) return;
      setState(() => _suggestions = suggestions);
    } catch (error) {
      if (kDebugMode) debugPrint('CityCargoOSM: address search failed: $error');
      if (!mounted) return;
      setState(() => _suggestions = const []);
      _showSnack('Не удалось найти адрес');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _selectSuggestion(AddressResult suggestion) async {
    FocusScope.of(context).unfocus();
    final point = LatLng(suggestion.lat, suggestion.lng);
    setState(() {
      _selectedPoint = point;
      _resolvedAddress = suggestion.address;
      _suggestions = const [];
      _ignoreSearchChanges = true;
      _searchCtrl.text = suggestion.address;
      _searchCtrl.selection =
          TextSelection.collapsed(offset: suggestion.address.length);
      _ignoreSearchChanges = false;
    });
    _mapCtrl.move(point, 16);
    await _loadRouteIfPossible();
  }

  Future<void> _reverseGeocode(LatLng point) async {
    if (!mounted) return;
    setState(() => _isResolvingAddress = true);
    try {
      final result = await ref.read(addressRepositoryProvider).reverse(point.latitude, point.longitude);
      if (!mounted) return;
      setState(() {
        _resolvedAddress = result.address;
        _ignoreSearchChanges = true;
        _searchCtrl.text = result.address;
        _searchCtrl.selection = TextSelection.collapsed(offset: result.address.length);
        _ignoreSearchChanges = false;
      });
    } catch (error) {
      if (kDebugMode) {
        debugPrint('CityCargoOSM: reverse geocode failed: $error');
      }
      if (!mounted) return;
      final fallback = _formatPoint(point);
      setState(() {
        _resolvedAddress = fallback;
        _ignoreSearchChanges = true;
        _searchCtrl.text = fallback;
        _searchCtrl.selection =
            TextSelection.collapsed(offset: fallback.length);
        _ignoreSearchChanges = false;
      });
    } finally {
      if (mounted) setState(() => _isResolvingAddress = false);
    }
  }

  Future<void> _selectMapPoint(LatLng point) async {
    // Legacy onTap method. Now handled by _onMapPositionChanged.
  }

  void _onMapPositionChanged(MapCamera position, bool hasGesture) {
    if (!hasGesture) return; // Only trigger if user manually pans map
    
    final point = position.center;

    setState(() {
      _selectedPoint = point;
      _suggestions = const [];
      _isPanning = true;
    });

    _panDebouncer.run(() async {
      if (!mounted) return;
      setState(() => _isPanning = false);
      await _reverseGeocode(point);
      await _loadRouteIfPossible();
    });
  }


  Future<void> _useMyLocation() async {
    setState(() => _isLocating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Геолокация отключена на устройстве');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showSnack('Нет разрешения на геолокацию');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      final point = LatLng(position.latitude, position.longitude);
      if (kDebugMode) {
        debugPrint(
          'CityCargoOSM: current location ${point.latitude}, ${point.longitude}',
        );
      }
      setState(() => _currentLocation = point);
      _mapCtrl.move(point, 16);
      await _selectMapPoint(point);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('CityCargoOSM: current location failed: $error');
      }
      _showSnack('Не удалось получить местоположение');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _loadRouteIfPossible() async {
    final start = _currentLocation;
    final end = _selectedPoint;
    if (start == null || end == null) return;

    setState(() {
      _isRouteLoading = true;
    });
    try {
      final points = await _routeService.loadDrivingRoute(
        start: start,
        end: end,
      );
      if (!mounted) return;
      setState(() => _routePoints = points);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _routePoints = const [];
      });
    } finally {
      if (mounted) setState(() => _isRouteLoading = false);
    }
  }

  void _confirm() {
    final selectedPoint = _selectedPoint;
    if (_isResolvingAddress || selectedPoint == null) return;
    context.pop(AddressResult(
      address: _resolvedAddress,
      lat: selectedPoint.latitude,
      lng: selectedPoint.longitude,
      source: 'openstreetmap',
    ));
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  static String _formatPoint(LatLng point) =>
      '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';

  @override
  Widget build(BuildContext context) {
    final isBusy =
        _isMapLoading || _isResolvingAddress || _isLocating || _isRouteLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Выбрать адрес')),
      body: Column(
        children: [
          _SearchPanel(
            controller: _searchCtrl,
            suggestions: _suggestions,
            isSearching: _isSearching,
            onSearch: () => _searchAddress(_searchCtrl.text.trim()),
            onSuggestionTap: _selectSuggestion,
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: OsmMap(
                    controller: _mapCtrl,
                    initialCenter: _astanaCenter,
                    initialZoom: 12,
                    selectedPoint: null, // Don't draw the static marker
                    courierPoint: _currentLocation,
                    routePoints: _routePoints,
                    isLoading: isBusy,
                    errorMessage: null,
                    onTap: _selectMapPoint,
                    onPositionChanged: _onMapPositionChanged,
                    onMapReady: () {
                      if (kDebugMode) {
                        debugPrint('CityCargoOSM: address picker map ready');
                      }
                      setState(() => _isMapLoading = false);
                    },
                    onTileError: (_) {
                      if (kDebugMode) {
                        debugPrint('CityCargoOSM: ignored single tile error');
                      }
                    },
                  ),
                ),
                Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(bottom: _isPanning ? 30 : 0),
                    child: const Icon(
                      Icons.place,
                      size: 48,
                      color: AppColors.primary,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _ConfirmPanel(
            address: _resolvedAddress,
            coordinates: _selectedPoint == null
                ? 'Нажмите на карту, чтобы выбрать точку'
                : _formatPoint(_selectedPoint!),
            hasSelection: _selectedPoint != null,
            isBusy: isBusy,
            onConfirm: _confirm,
            onMyLocation: _useMyLocation,
          ),
        ],
      ),
    );
  }
}

class _SearchPanel extends StatelessWidget {
  final TextEditingController controller;
  final List<AddressResult> suggestions;
  final bool isSearching;
  final VoidCallback onSearch;
  final ValueChanged<AddressResult> onSuggestionTap;

  const _SearchPanel({
    required this.controller,
    required this.suggestions,
    required this.isSearching,
    required this.onSearch,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.grayBg,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Поиск адреса...',
                    prefixIcon:
                        const Icon(Icons.search, color: AppColors.grayText),
                    suffixIcon: isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => controller.clear(),
                          ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    isDense: true,
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => onSearch(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 88,
                height: 48,
                child: ElevatedButton(
                  onPressed: onSearch,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(88, 48),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('Найти'),
                ),
              ),
            ],
          ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                border: Border.all(color: AppColors.border),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: suggestions.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppColors.border),
                itemBuilder: (context, index) {
                  final suggestion = suggestions[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.place_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      suggestion.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onTap: () => onSuggestionTap(suggestion),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConfirmPanel extends StatelessWidget {
  final String address;
  final String coordinates;
  final bool hasSelection;
  final bool isBusy;
  final VoidCallback onConfirm;
  final VoidCallback onMyLocation;

  const _ConfirmPanel({
    required this.address,
    required this.coordinates,
    required this.hasSelection,
    required this.isBusy,
    required this.onConfirm,
    required this.onMyLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.place, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasSelection ? address : 'Адрес не выбран',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        coordinates,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isBusy ? null : onMyLocation,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Мое местоположение'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isBusy || !hasSelection ? null : onConfirm,
                    child: const Text('Подтвердить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
