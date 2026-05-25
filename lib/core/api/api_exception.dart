import 'package:flutter/foundation.dart';

class ApiException implements Exception {
  final String code;
  final String message;
  final int? statusCode;
  final String? field;
  final int? attemptsLeft;
  final dynamic rawData;

  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.field,
    this.attemptsLeft,
    this.rawData,
  });

  factory ApiException.fromJson(Map<String, dynamic> json, int statusCode) {
    if (kDebugMode) debugPrint('API ERROR RAW: $json [HTTP $statusCode]');

    final errorField = json['error'];
    String code;
    String message;
    int? attemptsLeft;
    String? field;

    if (errorField is Map<String, dynamic>) {
      code = (errorField['code'] ?? json['code'] ?? _codeFromStatus(statusCode))
          .toString()
          .toUpperCase();
      message = (errorField['message'] ??
              errorField['msg'] ??
              json['message'] ??
              _messageFromStatus(statusCode))
          .toString();
      attemptsLeft = errorField['attempts_left'] as int?;
      field = errorField['field'] as String?;
    } else {
      code = (json['code'] ?? _codeFromStatus(statusCode))
          .toString()
          .toUpperCase();
      message = (errorField is String && errorField.isNotEmpty
              ? errorField
              : json['message'] ??
                  json['detail'] ??
                  json['msg'] ??
                  _messageFromStatus(statusCode))
          .toString();
      attemptsLeft = json['attempts_left'] as int?;
      field = json['field'] as String?;
    }

    return ApiException(
      code: code,
      message: message,
      statusCode: statusCode,
      field: field,
      attemptsLeft: attemptsLeft,
      rawData: json,
    );
  }

  factory ApiException.noInternet() => const ApiException(
        code: 'NO_INTERNET',
        message: 'Нет соединения с интернетом',
      );

  factory ApiException.server({int? statusCode}) => ApiException(
        code: 'INTERNAL_ERROR',
        message: 'Ошибка сервера, попробуйте позже',
        statusCode: statusCode,
      );

  String get userMessage {
    if (statusCode == 401) {
      return 'Сессия истекла. Войдите снова.';
    }

    if (statusCode == 403) {
      if (code == 'ORDER_FORBIDDEN' ||
          code == 'ORDER_ACCESS_DENIED' ||
          message.toLowerCase().contains('order access denied')) {
        return 'Этот заказ недоступен для вашей роли';
      }
      return 'Недостаточно прав для этого действия';
    }

    switch (code) {
      case 'INVALID_CREDENTIALS':
      case 'INVALID_LOGIN':
      case 'AUTH_FAILED':
      case 'UNAUTHORIZED':
        return _invalidCredentials;
      case 'TOKEN_EXPIRED':
        return 'Сессия истекла, войдите снова';
      case 'ACCOUNT_PENDING':
        return 'Ваша заявка на рассмотрении';
      case 'ACCOUNT_REJECTED':
        return 'Ваша заявка отклонена';
      case 'ACCOUNT_BLOCKED':
        return 'Аккаунт заблокирован';
      case 'PHONE_EXISTS':
        return 'Этот номер уже зарегистрирован';
      case 'INVALID_SECURITY_CODE':
        return 'Неверный код';
      case 'MAX_ATTEMPTS_EXCEEDED':
        return 'Превышено число попыток. Обратитесь к оператору';
      case 'SECURITY_CODE_EXPIRED':
        return 'Код устарел';
      case 'INVALID_ORDER_STATUS':
      case 'INVALID_STATUS_TRANSITION':
        return 'Действие недоступно';
      case 'NOT_FOUND':
        if (message.toLowerCase().contains('order')) {
          return 'Заказ не найден';
        }
        return 'Не найдено';
      case 'ORDER_FORBIDDEN':
      case 'ORDER_ACCESS_DENIED':
        return 'Этот заказ недоступен для вашей роли';
      case 'NO_INTERNET':
        return 'Нет соединения с интернетом';
      case 'SERVER_ERROR':
      case 'INTERNAL_ERROR':
        return message.isEmpty ? 'Ошибка сервера, попробуйте позже' : message;
      default:
        return message.isEmpty ? 'Неизвестная ошибка' : message;
    }
  }

  static const _invalidCredentials = 'Неверный телефон или пароль';

  static String _codeFromStatus(int statusCode) => switch (statusCode) {
        400 => 'BAD_REQUEST',
        401 => 'UNAUTHORIZED',
        403 => 'FORBIDDEN',
        404 => 'NOT_FOUND',
        422 => 'VALIDATION_ERROR',
        _ => 'UNKNOWN_ERROR',
      };

  static String _messageFromStatus(int statusCode) => switch (statusCode) {
        400 => 'Проверьте введенные данные',
        401 || 403 => _invalidCredentials,
        404 => 'Не найдено',
        422 => 'Проверьте введенные данные',
        _ => 'Неизвестная ошибка',
      };

  @override
  String toString() =>
      'ApiException($code): $message [HTTP $statusCode] raw=$rawData';
}
