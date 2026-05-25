import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../domain/models/auth_response_model.dart';
import '../domain/models/user_model.dart';

class AuthRemoteDataSource {
  final ApiClient _client;

  AuthRemoteDataSource(this._client);

  Future<AuthResponseModel> login(String phone, String password) async {
    final data = await _client.postFormData(
      '/api/v1/auth/login',
      FormData.fromMap({'phone': phone, 'password': password}),
    );
    debugPrint('LOGIN RESPONSE: $data');
    return AuthResponseModel.fromJson(data);
  }

  Future<void> logout() => _client.post('/api/v1/auth/logout');

  Future<UserModel> getMe() async {
    // Backend currently has no GET /me endpoint in the public API list.
    // AuthRepository falls back to the cached login user when this returns 404.
    final resp = await _client.get('/api/v1/me');
    final data = resp['data'] as Map<String, dynamic>? ?? resp;
    return UserModel.fromJson(data);
  }
}
