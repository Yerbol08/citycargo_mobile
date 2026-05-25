import '../api/api_exception.dart';

String userErrorMessage(
  Object error, {
  String fallback = 'Не удалось выполнить действие',
}) {
  if (error is ApiException) return error.userMessage;
  return fallback;
}
