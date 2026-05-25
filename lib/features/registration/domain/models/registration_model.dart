class ClientRegistrationModel {
  final String fullName;
  final String phone;
  final String? email;
  final String password;
  final String role;

  const ClientRegistrationModel({
    required this.fullName,
    required this.phone,
    this.email,
    required this.password,
    this.role = 'sender',
  });

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'phone': phone,
        if (email != null && email!.isNotEmpty) 'email': email,
        'password': password,
      };
}

class CourierRegistrationModel {
  final String fullName;
  final String phone;
  final String? email;
  final String password;
  final String vehicleType;
  final String? vehicleNumber;
  final String? comment;

  const CourierRegistrationModel({
    required this.fullName,
    required this.phone,
    this.email,
    required this.password,
    required this.vehicleType,
    this.vehicleNumber,
    this.comment,
  });

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'phone': phone,
        if (email != null && email!.isNotEmpty) 'email': email,
        'password': password,
        'transport_type': vehicleType,
        if (vehicleNumber != null && vehicleNumber!.isNotEmpty)
          'vehicle_number': vehicleNumber,
        if (comment != null && comment!.isNotEmpty) 'comment': comment,
      };
}
