import 'user_model.dart';

class AuthResponseModel {
  final String accessToken;
  final String? refreshToken;
  final UserModel user;

  const AuthResponseModel({
    required this.accessToken,
    this.refreshToken,
    required this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final token = data['access_token'] as String? ?? data['token'] as String?;
    final refresh = data['refresh_token'] as String?;
    
    if (token == null) throw Exception('No token in login response: $json');
    
    final userMap = data['user'] as Map<String, dynamic>? ?? data;
    
    return AuthResponseModel(
      accessToken: token,
      refreshToken: refresh,
      user: UserModel.fromJson(userMap),
    );
  }
}
