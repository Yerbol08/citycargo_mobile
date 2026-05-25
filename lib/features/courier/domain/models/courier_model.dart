import '../../../../core/utils/formatters.dart';

class CourierModel {
  final int id;
  final String fullName;
  final String phone;
  final String status;
  final String vehicleType;
  final String? vehicleNumber;
  final double rating;
  final int ordersToday;
  final int ordersTotal;
  final int earningsTodayMinor;

  const CourierModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.status,
    required this.vehicleType,
    this.vehicleNumber,
    this.rating = 0,
    this.ordersToday = 0,
    this.ordersTotal = 0,
    this.earningsTodayMinor = 0,
  });

  factory CourierModel.fromJson(Map<String, dynamic> json) => CourierModel(
        id: json['id'] as int,
        fullName: json['full_name'] as String,
        phone: json['phone'] as String,
        status: json['status'] as String? ?? 'pending',
        vehicleType: json['vehicle_type'] as String? ?? 'foot',
        vehicleNumber: json['vehicle_number'] as String?,
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        ordersToday: json['orders_today'] as int? ?? 0,
        ordersTotal: json['orders_total'] as int? ?? 0,
        earningsTodayMinor: json['earnings_today'] as int? ?? 0,
      );

  String get earningsTodayFormatted =>
      MoneyFormatter.format(earningsTodayMinor);

  String get vehicleLabel {
    switch (vehicleType) {
      case 'car':
        return 'Автомобиль';
      case 'motorcycle':
        return 'Мотоцикл';
      case 'bicycle':
        return 'Велосипед';
      default:
        return 'Пешком';
    }
  }
}
