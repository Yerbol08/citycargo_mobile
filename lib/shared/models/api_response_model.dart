import '../../core/utils/formatters.dart';
import '../../core/utils/api_helpers.dart';

class OrderSummary {
  final String id;
  final String number;
  final String status;
  final String? courierId;
  final String senderAddress;
  final String recipientAddress;
  final int priceMinor;
  final String currency;

  const OrderSummary({
    required this.id,
    required this.number,
    required this.status,
    this.courierId,
    required this.senderAddress,
    required this.recipientAddress,
    required this.priceMinor,
    required this.currency,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    final courierInfo = json['courier_info'];
    final courierInfoMap =
        courierInfo is Map ? Map<String, dynamic>.from(courierInfo) : null;
    return OrderSummary(
      id: (json['id'] ?? json['order_id'] ?? json['orderId'] ?? json['pk'])
              ?.toString() ??
          '',
      number: (json['order_number'] ?? json['number'] ?? json['orderNumber'])
              ?.toString() ??
          '',
      status:
          json['status']?.toString() ?? json['status_code']?.toString() ?? '',
      courierId: (json['courier_id'] ??
              json['courierId'] ??
              courierInfoMap?['id'] ??
              courierInfoMap?['user_id'])
          ?.toString(),
      senderAddress: json['sender_address'] as String? ?? '',
      recipientAddress: json['recipient_address'] as String? ?? '',
      priceMinor: parseInt(json['price_total_minor'] ?? json['price_minor']),
      currency:
          (json['currency_code'] ?? json['currency'])?.toString() ?? 'KZT',
    );
  }

  String get priceFormatted => MoneyFormatter.format(priceMinor);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'status': status,
      'courier_id': courierId,
      'sender_address': senderAddress,
      'recipient_address': recipientAddress,
      'price_minor': priceMinor,
      'currency': currency,
    };
  }
}
