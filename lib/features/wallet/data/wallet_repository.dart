import '../../../core/api/api_client.dart';
import '../../../core/utils/api_helpers.dart';
import '../domain/models/wallet_model.dart';

class WalletRepository {
  final ApiClient _client;

  WalletRepository(this._client);

  Future<WalletModel> getWallet() async {
    final data = await _client.get('/api/v1/me/wallets');
    final list = extractList(data['data'] ?? data);
    if (list.isEmpty) {
      return const WalletModel(id: '', balanceMinor: 0, currency: 'KZT');
    }
    return WalletModel.fromJson(list.first as Map<String, dynamic>);
  }

  Future<List<TransactionModel>> getTransactions(String walletId) async {
    final data = await _client.get(
      '/api/v1/wallets/$walletId/transactions',
      params: {'limit': 20},
    );
    final list = extractList(data['data'] ?? data);
    return list
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TopUpModel>> getMyTopUps() async {
    final data = await _client.get('/api/v1/me/topups', params: {
      'page': 1,
      'limit': 20,
    });
    final list = extractList(data['data'] ?? data);
    return list
        .map((e) => TopUpModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> topUp(int amountMinor, {String? comment}) async {
    await _client.post(
      '/api/v1/topups',
      data: {
        'amount_minor': amountMinor,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
    );
  }
}
