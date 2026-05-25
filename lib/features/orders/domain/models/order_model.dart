import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/api_helpers.dart';
import '../../../../shared/models/order_status.dart';

class OrderModel {
  final String id;
  final String number;
  final String status;
  final String senderPhone;
  final String senderAddress;
  final double senderLat;
  final double senderLng;
  final String recipientPhone;
  final String recipientAddress;
  final double recipientLat;
  final double recipientLng;
  final int parcelCount;
  final String? comment;
  final int priceMinor;
  final int courierRewardMinor;
  final int systemCommissionMinor;
  final String currency;
  final String? courierId;
  final String? courierName;
  final String? vehicleId;
  final String? financialHoldStatus;
  final String? courierPayoutStatus;
  final String? pickupCode;
  final String? deliveryCode;
  final DateTime? createdAt;

  const OrderModel({
    required this.id,
    required this.number,
    required this.status,
    required this.senderPhone,
    required this.senderAddress,
    required this.senderLat,
    required this.senderLng,
    required this.recipientPhone,
    required this.recipientAddress,
    required this.recipientLat,
    required this.recipientLng,
    required this.parcelCount,
    this.comment,
    required this.priceMinor,
    this.courierRewardMinor = 0,
    this.systemCommissionMinor = 0,
    required this.currency,
    this.courierId,
    this.courierName,
    this.vehicleId,
    this.financialHoldStatus,
    this.courierPayoutStatus,
    this.pickupCode,
    this.deliveryCode,
    this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final courierInfo = json['courier_info'];
    final courierInfoMap =
        courierInfo is Map ? Map<String, dynamic>.from(courierInfo) : null;
    final createdAtRaw =
        (json['created_at'] ?? json['createdAt'] ?? json['created'])
            ?.toString();

    return OrderModel(
      id: (json['id'] ?? json['order_id'] ?? json['orderId'] ?? json['pk'])
              ?.toString() ??
          '',
      number: (json['order_number'] ?? json['number'] ?? json['orderNumber'])
              ?.toString() ??
          '',
      status:
          json['status']?.toString() ?? json['status_code']?.toString() ?? '',
      senderPhone: json['sender_phone'] as String? ?? '',
      senderAddress: json['sender_address'] as String? ?? '',
      senderLat: (json['sender_lat'] as num?)?.toDouble() ?? 0,
      senderLng: (json['sender_lng'] as num?)?.toDouble() ?? 0,
      recipientPhone: json['recipient_phone'] as String? ?? '',
      recipientAddress: json['recipient_address'] as String? ?? '',
      recipientLat: (json['recipient_lat'] as num?)?.toDouble() ?? 0,
      recipientLng: (json['recipient_lng'] as num?)?.toDouble() ?? 0,
      parcelCount: parseInt(json['parcel_count'], fallback: 1),
      comment: json['comment'] as String?,
      priceMinor: parseInt(json['price_total_minor'] ?? json['price_minor']),
      courierRewardMinor: parseInt(json['courier_reward_minor']),
      systemCommissionMinor: parseInt(json['system_commission_minor']),
      currency:
          (json['currency_code'] ?? json['currency'])?.toString() ?? 'KZT',
      courierId: json['courier_id']?.toString(),
      courierName: _parseCourierName(courierInfoMap),
      vehicleId: json['vehicle_id']?.toString(),
      financialHoldStatus: json['financial_hold_status']?.toString(),
      courierPayoutStatus: json['courier_payout_status']?.toString(),
      pickupCode: json['pickup_code']?.toString(),
      deliveryCode: json['delivery_code']?.toString(),
      createdAt: createdAtRaw == null ? null : DateTime.tryParse(createdAtRaw),
    );
  }

  String get priceFormatted => MoneyFormatter.format(priceMinor);
  String get courierRewardFormatted =>
      MoneyFormatter.format(courierRewardMinor);
  String get systemCommissionFormatted =>
      MoneyFormatter.format(systemCommissionMinor);

  static String? _parseCourierName(Map<String, dynamic>? courierInfo) {
    if (courierInfo == null) return null;
    final firstName = courierInfo['first_name']?.toString().trim() ?? '';
    final lastName = courierInfo['last_name']?.toString().trim() ?? '';
    final fullName = [firstName, lastName].where((v) => v.isNotEmpty).join(' ');
    if (fullName.isNotEmpty) return fullName;
    return courierInfo['name']?.toString();
  }

  bool get isActive => OrderStatusMapper.info(status).isActive;
}
