class Validators {
  static String? phone(String? v) {
    if (v == null || v.isEmpty) return 'Телефон обязателен';
    final clean = v.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!RegExp(r'^\+7\d{10}$').hasMatch(clean)) return 'Формат: +7XXXXXXXXXX';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Пароль обязателен';
    if (v.length < 8) return 'Минимум 8 символов';
    return null;
  }

  static String? passwordConfirm(String? v, String password) {
    if (v == null || v.isEmpty) return 'Подтверждение пароля обязательно';
    if (v != password) return 'Пароли не совпадают';
    return null;
  }

  static String? required(String? v, String fieldName) {
    if (v == null || v.trim().isEmpty) return '$fieldName обязательно';
    return null;
  }

  static String? email(String? v) {
    if (v == null || v.isEmpty) return null;
    if (!RegExp(r'^[\w\-\.]+@[\w\-]+\.[a-z]{2,}$').hasMatch(v)) {
      return 'Некорректный email';
    }
    return null;
  }
}
