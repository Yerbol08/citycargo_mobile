import 'package:dio/dio.dart';
import '../storage/token_storage.dart';
import '../config/app_config.dart';

class AuthInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;
  final Function() _onUnauthorized;
  final Function(String code) _onForbidden;
  final Dio _dio;
  bool _isRefreshing = false;
  final _failedRequests = <_FailedRequest>[];

  AuthInterceptor({
    required TokenStorage tokenStorage,
    required Function() onUnauthorized,
    required Function(String code) onForbidden,
    required Dio dio,
  })  : _tokenStorage = tokenStorage,
        _onUnauthorized = onUnauthorized,
        _onForbidden = onForbidden,
        _dio = dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      if (_isRefreshing) {
        _failedRequests.add(_FailedRequest(err.requestOptions, handler));
        return;
      }

      _isRefreshing = true;
      _failedRequests.add(_FailedRequest(err.requestOptions, handler));

      try {
        final refreshToken = await _tokenStorage.getRefreshToken();
        if (refreshToken == null) {
          throw DioException(requestOptions: err.requestOptions);
        }

        final response = await _dio.post(
          '${AppConfig.apiUrl}/api/v1/auth/refresh',
          data: {'refresh_token': refreshToken},
        );

        final newAccessToken = response.data['access_token'];
        final newRefreshToken = response.data['refresh_token'];

        await _tokenStorage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );

        _isRefreshing = false;

        // Retry failed requests
        for (final request in _failedRequests) {
          request.options.headers['Authorization'] = 'Bearer $newAccessToken';
          final retryResponse = await _dio.fetch(request.options);
          request.handler.resolve(retryResponse);
        }
        _failedRequests.clear();
        return;
      } catch (e) {
        _isRefreshing = false;
        _failedRequests.clear();
        _onUnauthorized();
      }
    }

    if (err.response?.statusCode == 403) {
      final data = err.response?.data as Map<String, dynamic>?;
      final code = data?['error']?['code'] as String? ?? '';
      _onForbidden(code);
    }
    
    handler.next(err);
  }
}

class _FailedRequest {
  final RequestOptions options;
  final ErrorInterceptorHandler handler;

  _FailedRequest(this.options, this.handler);
}
