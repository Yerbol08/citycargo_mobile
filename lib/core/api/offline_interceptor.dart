import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../services/sync_queue_service.dart';

class OfflineInterceptor extends Interceptor {
  final SyncQueueService Function() getSyncQueue;

  OfflineInterceptor({required this.getSyncQueue});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_isConnectionError(err) && _isMutatingRequest(err.requestOptions)) {
      if (kDebugMode) debugPrint('OfflineInterceptor: Network error, saving request to queue');
      
      try {
        await getSyncQueue().enqueue(
          err.requestOptions.method,
          err.requestOptions.path,
          data: err.requestOptions.data is Map<String, dynamic>
              ? err.requestOptions.data as Map<String, dynamic>
              : null,
        );
        
        // Return a mock successful response so the UI thinks it succeeded
        return handler.resolve(
          Response(
            requestOptions: err.requestOptions,
            statusCode: 202, // Accepted
            data: {'success': true, 'offline': true},
          ),
        );
      } catch (e) {
        if (kDebugMode) debugPrint('OfflineInterceptor: Failed to save to queue - $e');
      }
    }
    
    return handler.next(err);
  }

  bool _isConnectionError(DioException err) {
    return err.type == DioExceptionType.connectionError ||
           err.type == DioExceptionType.connectionTimeout ||
           err.type == DioExceptionType.sendTimeout ||
           err.type == DioExceptionType.receiveTimeout;
  }

  bool _isMutatingRequest(RequestOptions options) {
    final method = options.method.toUpperCase();
    return method == 'POST' || method == 'PUT' || method == 'PATCH' || method == 'DELETE';
  }
}
