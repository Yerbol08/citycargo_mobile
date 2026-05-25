import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../config/app_config.dart';
import '../storage/token_storage.dart';
import '../services/sync_queue_service.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';
import 'offline_interceptor.dart';

class ApiClient {
  late final Dio _dio;
  Dio get dio => _dio;
  final TokenStorage tokenStorage;
  late final SyncQueueService syncQueue;

  ApiClient({
    required this.tokenStorage,
    required Function() onUnauthorized,
    required Function(String) onForbidden,
  }) {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
    ));
    syncQueue = SyncQueueService(_dio);
    syncQueue.init();

    // Logging interceptor
    if (kDebugMode) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            debugPrint('=== REQUEST ===');
            debugPrint('URL: ${options.baseUrl}${options.path}');
            debugPrint('METHOD: ${options.method}');
            debugPrint('PARAMS: ${_safeLog(options.queryParameters)}');
            debugPrint('DATA: ${_safeLog(options.data)}');
            handler.next(options);
          },
          onResponse: (response, handler) {
            debugPrint('=== RESPONSE ===');
            debugPrint('STATUS: ${response.statusCode}');
            debugPrint('DATA: ${_safeLog(response.data)}');
            handler.next(response);
          },
          onError: (error, handler) {
            debugPrint('=== ERROR ===');
            debugPrint('URL: ${error.requestOptions.uri}');
            debugPrint('STATUS: ${error.response?.statusCode}');
            debugPrint('DATA: ${_safeLog(error.response?.data)}');
            debugPrint('MESSAGE: ${error.message}');
            handler.next(error);
          },
        ),
      );
    }

    _dio.interceptors.add(OfflineInterceptor(getSyncQueue: () => syncQueue));
    _dio.interceptors.add(AuthInterceptor(
      tokenStorage: tokenStorage,
      onUnauthorized: onUnauthorized,
      onForbidden: onForbidden,
      dio: _dio,
    ));
  }

  Future<Map<String, dynamic>> get(String path,
      {Map<String, dynamic>? params}) async {
    try {
      final response = await _dio.get(path, queryParameters: params);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> post(String path, {dynamic data}) async {
    try {
      final response = await _dio.post(path, data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> put(String path, {dynamic data}) async {
    try {
      final response = await _dio.put(path, data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> patch(String path, {dynamic data}) async {
    try {
      final response = await _dio.patch(path, data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> postFormData(
      String path, FormData formData) async {
    try {
      final response = await _dio.post(path, data: formData);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  ApiException _handleError(DioException e) {
    if (kDebugMode) debugPrint('API ERROR TYPE: ${e.type}');
    
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return ApiException.noInternet();
    }

    final response = e.response;
    final statusCode = response?.statusCode ?? 0;
    final data = response?.data;

    ApiException apiException;

    if (data is Map<String, dynamic>) {
      apiException = ApiException.fromJson(data, statusCode);
    } else if (data is String && data.isNotEmpty) {
      apiException = ApiException(
        code: statusCode == 401 || statusCode == 403
            ? 'UNAUTHORIZED'
            : 'SERVER_ERROR',
        message: data.length > 200 ? data.substring(0, 200) : data,
        statusCode: statusCode,
      );
    } else {
      apiException = ApiException.server(statusCode: statusCode);
    }

    // Capture critical errors in Sentry
    if (statusCode >= 500 || statusCode == 0) {
      Sentry.captureException(apiException, stackTrace: StackTrace.current);
    }

    return apiException;
  }

  String _safeLog(Object? value) {
    final raw = value.toString().replaceAll(
          RegExp(r'eyJ[a-zA-Z0-9_\-.]+'),
          '***JWT***',
        );
    return raw.length > 1200 ? '${raw.substring(0, 1200)}...' : raw;
  }
}
