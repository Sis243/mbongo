import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../store/mbongo_store.dart';
import '../data/wallet_repository.dart';
import '../domain/wallet_state.dart';

final walletProvider = AsyncNotifierProvider<WalletNotifier, WalletData?>(
  WalletNotifier.new,
);

class WalletNotifier extends AsyncNotifier<WalletData?> {
  @override
  Future<WalletData?> build() async {
    // Return local data instantly — no loading spinner
    _tryRefreshFromApi();
    return _localFallback();
  }

  Future<void> _tryRefreshFromApi() async {
    try {
      final data = await ref
          .read(walletRepositoryProvider)
          .fetchWallet()
          .timeout(const Duration(seconds: 8));
      state = AsyncData(data);
    } catch (_) {}
  }

  Future<WalletData?> _load() async {
    try {
      return await ref
          .read(walletRepositoryProvider)
          .fetchWallet()
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      return _localFallback();
    }
  }

  WalletData _localFallback() {
    final wallet = MbongoStore.getSelectedWallet();
    final txMaps = MbongoStore.transactionMaps();
    return WalletData(
      id: wallet.id,
      balance: wallet.balance,
      currency: wallet.currency,
      transactions: txMaps.map(TxEntry.fromMap).toList(),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _load());
  }

  // Optimistic debit — met à jour le solde localement avant confirmation serveur
  void optimisticDebit(double amount) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(balance: current.balance - amount));
  }

  // Ajoute une transaction locale immédiatement (optimistic)
  void addLocalTransaction(TxEntry tx) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(transactions: [tx, ...current.transactions]),
    );
  }
}
