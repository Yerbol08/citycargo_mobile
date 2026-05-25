import 'package:intl/intl.dart';

class MoneyFormatter {
  static String format(int amountMinor) {
    final tenge = amountMinor / 100;
    final digits = tenge == tenge.truncateToDouble() ? 0 : 2;
    return NumberFormat.currency(
      locale: 'ru_KZ',
      symbol: '₸',
      decimalDigits: digits,
    ).format(tenge);
  }
}

class DateFormatter {
  static String formatDateTime(DateTime dt) =>
      DateFormat('dd.MM.yyyy HH:mm', 'ru').format(dt.toLocal());

  static String formatDate(DateTime dt) =>
      DateFormat('dd.MM.yyyy', 'ru').format(dt.toLocal());

  static String formatTime(DateTime dt) =>
      DateFormat('HH:mm', 'ru').format(dt.toLocal());
}
