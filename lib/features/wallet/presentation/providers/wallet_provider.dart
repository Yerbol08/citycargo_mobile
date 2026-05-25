import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/wallet_repository.dart';
import '../../domain/models/wallet_model.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(ref.watch(apiClientProvider));
});

class WalletState {
  final WalletModel? wallet;
  final List<TransactionModel> transactions;
  final List<TopUpModel> topUps;
  final bool isLoading;
  final String? error;

  const WalletState({
    this.wallet,
    this.transactions = const [],
    this.topUps = const [],
    this.isLoading = false,
    this.error,
  });

  WalletState copyWith({
    WalletModel? wallet,
    List<TransactionModel>? transactions,
    List<TopUpModel>? topUps,
    bool? isLoading,
    String? error,
  }) =>
      WalletState(
        wallet: wallet ?? this.wallet,
        transactions: transactions ?? this.transactions,
        topUps: topUps ?? this.topUps,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
      );
}

class WalletNotifier extends StateNotifier<WalletState> {
  final WalletRepository _repo;

  WalletNotifier(this._repo) : super(const WalletState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final wallet = await _repo.getWallet();
      final txs = wallet.id.isNotEmpty
          ? await _repo.getTransactions(wallet.id)
          : <TransactionModel>[];
      final topUps = await _repo.getMyTopUps();
      state = state.copyWith(
        wallet: wallet,
        transactions: txs,
        topUps: topUps,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: userErrorMessage(
          e,
          fallback: 'Не удалось загрузить кошелек',
        ),
      );
    }
  }

  Future<void> topUp(int amountMinor, {String? comment}) async {
    try {
      await _repo.topUp(amountMinor, comment: comment);
      await load();
    } catch (e) {
      state = state.copyWith(
        error: userErrorMessage(
          e,
          fallback: 'Не удалось создать заявку на пополнение',
        ),
      );
      rethrow;
    }
  }
}

final walletProvider =
    StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  return WalletNotifier(ref.watch(walletRepositoryProvider));
});
