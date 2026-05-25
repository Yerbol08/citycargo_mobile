import '../../../../app/app_role.dart';

class UserModel {
  final String id;
  final String phone;
  final String fullName;
  final List<AppRole> roles;

  const UserModel({
    required this.id,
    required this.phone,
    required this.fullName,
    required this.roles,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final roles = _parseRoles(json);
    return UserModel(
      id: json['user_id'] as String? ?? json['id']?.toString() ?? '',
      phone: json['phone'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      roles: roles.normalizedForApp,
    );
  }

  String get role => primaryRole.code;
  AppRole get primaryRole => roles.isEmpty ? AppRole.customer : roles.first;

  bool get isClient => roles.any((role) => const [
        AppRole.customer,
        AppRole.sender,
        AppRole.recipient
      ].contains(role));
  bool get isCourier => roles.contains(AppRole.courier);
  bool get isOperator => roles.contains(AppRole.operator);
  bool get isModerator => roles.contains(AppRole.moderator);

  Map<String, dynamic> toJson() => {
        'user_id': id,
        'phone': phone,
        'full_name': fullName,
        'roles': roles.map((role) => role.code).toList(),
      };

  static List<AppRole> _parseRoles(Map<String, dynamic> json) {
    final rolesRaw = json['roles'] ?? json['role_codes'] ?? json['roleCodes'];
    final values = <String>[];

    if (rolesRaw is List) {
      for (final item in rolesRaw) {
        if (item is Map) {
          values.add((item['code'] ?? item['name'] ?? '').toString());
        } else {
          values.add(item.toString());
        }
      }
    } else {
      values.add(
        (json['role'] ?? json['role_code'] ?? json['roleCode'] ?? '')
            .toString(),
      );
    }

    final parsed = values
        .map(AppRole.fromCode)
        .whereType<AppRole>()
        .toList(growable: false);
    return parsed.isEmpty ? const [AppRole.customer] : parsed;
  }
}
