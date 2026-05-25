class CreateOrderParams {
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

  const CreateOrderParams({
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
  });
}
