class AddressResult {
  final String address;
  final double lat;
  final double lng;
  final String source;

  const AddressResult({
    required this.address,
    required this.lat,
    required this.lng,
    required this.source,
  });

  bool get hasCoordinates => lat != 0.0 && lng != 0.0;
}
