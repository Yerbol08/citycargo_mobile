import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/orders_remote_datasource.dart';
import '../../data/orders_repository.dart';
import '../../domain/models/order_model.dart';

import '../../../../shared/models/api_response_model.dart';
import '../../data/osm_address_repository.dart';
import '../../domain/repositories/address_repository.dart';

final addressRepositoryProvider = Provider<AddressRepository>((ref) => OsmAddressRepository());

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepository(
    OrdersRemoteDataSource(ref.watch(apiClientProvider)),
    syncQueue: ref.watch(syncQueueServiceProvider),
  );
});

class OrdersState {
  final List<OrderSummary> orders;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final String? error;

  const OrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
  });

  OrdersState copyWith({
    List<OrderSummary>? orders,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? error,
    bool clearError = false,
  }) =>
      OrdersState(
        orders: orders ?? this.orders,
        isLoading: isLoading ?? this.isLoading,
        isRefreshing: isRefreshing ?? this.isRefreshing,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        page: page ?? this.page,
        error: clearError ? null : (error ?? this.error),
      );
}

class OrdersNotifier extends StateNotifier<OrdersState> {
  final OrdersRepository _repo;
  final bool _courierMode;
  final String? _courierId;

  OrdersNotifier(
    this._repo, {
    bool courierMode = false,
    String? courierId,
  })  : _courierMode = courierMode,
        _courierId = courierId,
        super(const OrdersState());

  Future<void> load({String? status, bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(isRefreshing: true, clearError: true, page: 1, hasMore: true);
    } else {
      state = state.copyWith(isLoading: true, clearError: true, page: 1, hasMore: true);
    }
    try {
      final cacheKey = _courierMode ? 'courier_orders_$_courierId' : 'client_orders_$status';
      final box = Hive.box('orders_cache');
      final cachedStr = box.get(cacheKey);
      if (cachedStr != null && cachedStr is String) {
        final List decoded = jsonDecode(cachedStr);
        final cachedOrders = decoded.map((e) => OrderSummary.fromJson(Map<String, dynamic>.from(e))).toList();
        state = state.copyWith(orders: cachedOrders, isLoading: false);
      }
    } catch (_) {}

    try {
      final orders = _courierMode
          ? await _repo.getCourierOrders(courierId: _courierId)
          : await _repo.getOrders(status: status, page: 1, limit: 20);
          
      final cacheKey = _courierMode ? 'courier_orders_$_courierId' : 'client_orders_$status';
      try {
        final box = Hive.box('orders_cache');
        final encoded = jsonEncode(orders.map((e) => e.toJson()).toList());
        box.put(cacheKey, encoded);
      } catch (_) {}

      state = state.copyWith(
        orders: orders,
        isLoading: false,
        isRefreshing: false,
        hasMore: orders.length == 20,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: userErrorMessage(
          e,
          fallback: 'Не удалось загрузить заказы',
        ),
      );
    }
  }

  Future<void> loadMore({String? status}) async {
    if (_courierMode || !state.hasMore || state.isLoading || state.isLoadingMore || state.isRefreshing) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.page + 1;
      final newOrders = await _repo.getOrders(status: status, page: nextPage, limit: 20);

      final combined = [...state.orders, ...newOrders];

      final cacheKey = 'client_orders_$status';
      try {
        final box = Hive.box('orders_cache');
        final encoded = jsonEncode(combined.map((e) => e.toJson()).toList());
        box.put(cacheKey, encoded);
      } catch (_) {}

      state = state.copyWith(
        orders: combined,
        page: nextPage,
        hasMore: newOrders.length == 20,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }
}

final ordersProvider =
    StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  return OrdersNotifier(ref.watch(ordersRepositoryProvider));
});

final courierOrdersProvider =
    StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  final id = ref.watch(authProvider).user?.id;
  return OrdersNotifier(
    ref.watch(ordersRepositoryProvider),
    courierMode: true,
    courierId: id,
  );
});

final orderDetailProvider =
    FutureProvider.family<OrderModel, String>((ref, orderNumber) async {
  return ref.watch(ordersRepositoryProvider).getOrder(orderNumber);
});

enum CourierArrivalStep {
  none,
  arrivedAtSender,
  arrivedAtRecipient,
}

final courierArrivalStepProvider =
    StateProvider.family<CourierArrivalStep, String>(
  (ref, orderNumber) => CourierArrivalStep.none,
);
