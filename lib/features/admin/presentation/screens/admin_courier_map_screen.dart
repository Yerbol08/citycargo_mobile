import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../shared/widgets/osm_map.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_cards.dart';

class AdminCourierMapScreen extends ConsumerStatefulWidget {
  const AdminCourierMapScreen({super.key});

  @override
  ConsumerState<AdminCourierMapScreen> createState() =>
      _AdminCourierMapScreenState();
}

class _AdminCourierMapScreenState extends ConsumerState<AdminCourierMapScreen> {
  static const _astana = LatLng(51.1605, 71.4704);

  late Future<List<Map<String, dynamic>>> _future;
  final _searchCtrl = TextEditingController();
  Map<String, dynamic>? _selectedCourier;
  LatLng? _selectedLocation;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _searchCtrl.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _load() {
    return ref.read(adminRepositoryProvider).getCouriers();
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _selectCourier(Map<String, dynamic> courier) async {
    setState(() {
      _selectedCourier = courier;
      _selectedLocation = null;
      _locationError = null;
    });
    final userId = _text(courier, ['user_id', 'id', 'courier_id']);
    try {
      final location =
          await ref.read(adminRepositoryProvider).getLocation(userId);
      final lat = double.tryParse(_text(location, ['latitude', 'lat']));
      final lng = double.tryParse(_text(location, ['longitude', 'lng', 'lon']));
      if (lat == null || lng == null) {
        setState(() => _locationError = 'Локация недоступна');
        return;
      }
      setState(() => _selectedLocation = LatLng(lat, lng));
    } catch (e) {
      setState(() => _locationError = 'Локация недоступна');
    }
  }

  Future<void> _openNavigator() async {
    final point = _selectedLocation;
    if (point == null) return;
    final uri = Uri.parse(
        'geo:${point.latitude},${point.longitude}?q=${point.latitude},${point.longitude}');
    final web = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${point.latitude},${point.longitude}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await launchUrl(web, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snap) {
        var couriers = snap.data ?? const <Map<String, dynamic>>[];
        final query = _searchCtrl.text.trim().toLowerCase();
        if (query.isNotEmpty) {
          couriers = couriers.where((c) {
            final name = _text(c, ['full_name', 'name', 'phone']).toLowerCase();
            return name.contains(query);
          }).toList();
        }
        return AdminListScaffold(
          title: 'Карта исполнителей',
          isLoading: snap.connectionState == ConnectionState.waiting,
          error: snap.hasError
              ? userErrorMessage(
                  snap.error!,
                  fallback: 'Не удалось загрузить карту исполнителей',
                )
              : null,
          onRefresh: _refresh,
          header: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                child: SizedBox(
                  height: 250,
                  child: OsmMap(
                    initialCenter: _selectedLocation ?? _astana,
                    initialZoom: _selectedLocation == null ? 11 : 15,
                    courierPoint: _selectedLocation,
                    showZoomControls: false,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Поиск курьера...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              if (_selectedCourier != null) ...[
                const SizedBox(height: 10),
                AdminDataCard(
                  title:
                      _text(_selectedCourier!, ['full_name', 'name', 'phone']),
                  subtitle: _locationError ?? 'Курьер выбран',
                  icon: Icons.delivery_dining,
                  color: AppColors.courier,
                  actions: [
                    ElevatedButton.icon(
                      onPressed:
                          _selectedLocation == null ? null : _openNavigator,
                      icon: const Icon(Icons.navigation_outlined, size: 18),
                      label: const Text('Навигатор'),
                    ),
                  ],
                ),
              ],
            ],
          ),
          children: [
            for (final courier in couriers)
              AdminDataCard(
                title: _text(courier, ['full_name', 'name', 'phone']),
                subtitle: _text(courier, ['phone', 'status', 'transport_type']),
                trailing: _text(courier, ['status']),
                icon: Icons.delivery_dining,
                color: AppColors.courier,
                onTap: () => _selectCourier(courier),
              ),
          ],
        );
      },
    );
  }

  String _text(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return '-';
  }
}
