import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/offline_queue.dart';

class OfflineSyncService {
  final OfflineQueue _offlineQueue;
  final Dio _dio;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isSyncing = false;

  OfflineSyncService({
    required OfflineQueue offlineQueue,
    required Dio dio,
  })  : _offlineQueue = offlineQueue,
        _dio = dio;

  void startListening() {
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      if (results.contains(ConnectivityResult.mobile) || 
          results.contains(ConnectivityResult.wifi) || 
          results.contains(ConnectivityResult.ethernet)) {
        _syncOfflineRequests();
      }
    });
    
    // Attempt sync on startup
    _syncOfflineRequests();
  }

  void stopListening() {
    _subscription?.cancel();
  }

  Future<void> _syncOfflineRequests() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final pendingRequests = _offlineQueue.getPendingRequests();
      if (pendingRequests.isEmpty) {
        _isSyncing = false;
        return;
      }

      if (kDebugMode) debugPrint('OfflineSyncService: Found ${pendingRequests.length} pending requests, starting sync...');

      for (var entry in pendingRequests) {
        final key = entry.key;
        final req = entry.value;

        try {
          if (req.method == 'POST') {
            await _dio.post(req.path, data: req.data);
          } else if (req.method == 'PUT') {
            await _dio.put(req.path, data: req.data);
          } else if (req.method == 'PATCH') {
            await _dio.patch(req.path, data: req.data);
          } else if (req.method == 'DELETE') {
            await _dio.delete(req.path, data: req.data);
          }

          // If successful, remove from queue
          await _offlineQueue.remove(key);
          if (kDebugMode) debugPrint('OfflineSyncService: Successfully synced request to ${req.path}');
        } catch (e) {
          if (e is DioException) {
            final isNetworkError = e.type == DioExceptionType.connectionError ||
                                   e.type == DioExceptionType.connectionTimeout ||
                                   e.type == DioExceptionType.sendTimeout ||
                                   e.type == DioExceptionType.receiveTimeout;
            
            if (isNetworkError) {
              if (kDebugMode) debugPrint('OfflineSyncService: Network error during sync, aborting sync for now');
              break; // Stop syncing and wait for next connection event
            } else {
              // Server error (e.g. 400, 500) or client error. Remove from queue to prevent infinite loop.
              await _offlineQueue.remove(key);
              if (kDebugMode) debugPrint('OfflineSyncService: Server error syncing request, dropping it - $e');
            }
          }
        }
      }
    } finally {
      _isSyncing = false;
    }
  }
}
