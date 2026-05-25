import '../models/address_result.dart';

abstract class AddressRepository {
  Future<List<AddressResult>> search(String query);
  Future<AddressResult> reverse(double lat, double lng);
}
