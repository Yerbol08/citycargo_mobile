import '../../../../core/utils/api_helpers.dart';
import '../../../../core/utils/formatters.dart';

class WalletModel {
  final String id;
  final int balanceMinor;
  final String currency;

  const WalletModel({
    required this.id,
    required this.balanceMinor,
    required this.currency,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) => WalletModel(
        id: json['id']?.toString() ?? '',
        balanceMinor: parseInt(json['balance_minor']),
        currency:
            (json['currency_code'] ?? json['currency'])?.toString() ?? 'KZT',
      );

  String get balanceFormatted => MoneyFormatter.format(balanceMinor);
}

class TransactionModel {
  final String id;
  final String type;
  final int amountMinor;
  final String description;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.amountMinor,
    required this.description,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: json['id']?.toString() ?? '',
        type: (json['type'] ?? json['direction']).toString(),
        amountMinor: parseInt(json['amount_minor']),
        description:
            (json['description'] ?? json['comment'] ?? json['reason'] ?? '')
                .toString(),
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );

  String get amountFormatted => MoneyFormatter.format(amountMinor);
  bool get isCredit => type == 'credit';
}

class TopUpModel {
  final String id;
  final int amountMinor;
  final String status;
  final String comment;
  final String? reason;
  final DateTime? createdAt;

  const TopUpModel({
    required this.id,
    required this.amountMinor,
    required this.status,
    required this.comment,
    this.reason,
    this.createdAt,
  });

  factory TopUpModel.fromJson(Map<String, dynamic> json) {
    final rawDate = (json['created_at'] ?? json['createdAt'])?.toString();
    return TopUpModel(
      id: json['id']?.toString() ?? '',
      amountMinor: parseInt(json['amount_minor']),
      status: (json['status'] ?? json['status_code'] ?? '').toString(),
      comment: (json['comment'] ?? '').toString(),
      reason: json['reason']?.toString(),
      createdAt: rawDate == null ? null : DateTime.tryParse(rawDate),
    );
  }

  String get amountFormatted => MoneyFormatter.format(amountMinor);
}
