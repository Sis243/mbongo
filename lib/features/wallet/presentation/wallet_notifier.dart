import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/wallet_repository.dart';
import '../domain/wallet_state.dart';

final walletProvider = AsyncNotifierProvider<WalletNotifier, WalletData?>(
  WalletNotifier.new,
);

const _cacheKey = 'mbongo_wallet_cache';

class WalletNotifier extends AsyncNotifier<WalletData?> {
  @override
  Future<WalletData?> build() async {
    try {
      final data = await ref
          .read(walletRepositoryProvider)
          .fetchWallet()
          .timeout(const Duration(seconds: 8));
      unawaited(_saveCache(data));
      return data;
    } catch (_) {
      return _loadCache();
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final data = await ref
          .read(walletRepositoryProvider)
          .fetchWallet()
          .timeout(const Duration(seconds: 8));
      unawaited(_saveCache(data));
      state = AsyncData(data);
    } catch (_) {
      final cached = await _loadCache();
      state = AsyncData(cached);
    }
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

  // ── Cache SharedPreferences ───────────────────────────────────────────────

  Future<void> _saveCache(WalletData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode({
        'id': data.id,
        'balance': data.balance,
        'currency': data.currency,
        'transactions': data.transactions.map((t) => t.toMap()).toList(),
        'extraBalances': data.extraBalances,
      });
      await prefs.setString(_cacheKey, json);
    } catch (_) {}
  }

  Future<WalletData?> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return null;
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final txList = (m['transactions'] as List?)
              ?.map((e) => TxEntry.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [];
      final extra = (m['extraBalances'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];
      return WalletData(
        id: m['id']?.toString() ?? '',
        balance: ((m['balance'] ?? 0) as num).toDouble(),
        currency: m['currency']?.toString() ?? 'CDF',
        transactions: txList,
        extraBalances: extra,
        fromCache: true,
      );
    } catch (_) {
      return null;
    }
  }
}

// ignore: prefer_void_to_null
void unawaited(Future<void> future) {}
