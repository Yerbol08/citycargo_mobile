enum AppRole {
  customer('customer'),
  sender('sender'),
  recipient('recipient'),
  courier('courier'),
  operator('operator'),
  moderator('moderator');

  final String code;
  const AppRole(this.code);

  static AppRole? fromCode(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;
    return AppRole.values.where((role) => role.code == normalized).firstOrNull;
  }

  String get shellPath => switch (this) {
        AppRole.moderator => '/app/moderator',
        AppRole.operator => '/app/operator',
        AppRole.courier => '/app/courier',
        AppRole.customer ||
        AppRole.sender ||
        AppRole.recipient =>
          '/app/customer',
      };

  String get title => switch (this) {
        AppRole.moderator =>
          '\u041c\u043e\u0434\u0435\u0440\u0430\u0442\u043e\u0440',
        AppRole.operator => '\u041e\u043f\u0435\u0440\u0430\u0442\u043e\u0440',
        AppRole.courier => '\u041a\u0443\u0440\u044c\u0435\u0440',
        AppRole.sender =>
          '\u041e\u0442\u043f\u0440\u0430\u0432\u0438\u0442\u0435\u043b\u044c',
        AppRole.recipient =>
          '\u041f\u043e\u043b\u0443\u0447\u0430\u0442\u0435\u043b\u044c',
        AppRole.customer => '\u041a\u043b\u0438\u0435\u043d\u0442',
      };
}

extension AppRoleListX on List<AppRole> {
  List<AppRole> get normalizedForApp {
    final result = <AppRole>[];
    if (contains(AppRole.moderator)) result.add(AppRole.moderator);
    if (contains(AppRole.operator)) result.add(AppRole.operator);
    if (contains(AppRole.courier)) result.add(AppRole.courier);
    if (contains(AppRole.sender) ||
        contains(AppRole.recipient) ||
        contains(AppRole.customer)) {
      result.add(AppRole.customer);
    }
    return result.isEmpty ? const [AppRole.customer] : result;
  }
}
