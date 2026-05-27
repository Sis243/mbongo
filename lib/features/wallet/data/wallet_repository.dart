import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_client.dart';
import '../domain/wallet_state.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(ref.read(dioClientProvider));
});

class WalletRepository {
  final DioClient _client;
  const WalletRepository(this._client);

  Future<WalletData> fetchWallet() async {
    final walletResp = await _client.get('/wallet/me');
    final txResp = await _client.get('/transactions');
    final txList = txResp['data'];
    final transactions = (txList is List)
        ? txList
            .map((e) => TxEntry.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList()
        : <TxEntry>[];
    final balancesList = walletResp['balances'];
    final extraBalances = (balancesList is List)
        ? balancesList
            .map((e) => Map<String, dynamic>.from(e as Map))
            .where((e) => e['currency']?.toString() != (walletResp['currency']?.toString() ?? 'CDF'))
            .toList()
        : <Map<String, dynamic>>[];

    return WalletData(
      id: walletResp['id']?.toString() ?? '',
      balance: ((walletResp['balance'] ?? 0) as num).toDouble(),
      currency: walletResp['currency']?.toString() ?? 'CDF',
      transactions: transactions,
      extraBalances: extraBalances,
    );
  }

  Future<List<TxEntry>> fetchLedger() async {
    final resp = await _client.get('/wallet/me/ledger');
    final list = resp['data'];
    if (list is! List) return [];
    return list
        .map((e) => TxEntry.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchCashAgents() async {
    final resp = await _client.get('/transactions/cash-agents');
    final list = resp['data'];
    if (list is! List) return [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchCurrencies() async {
    final resp = await _client.get('/merchant/currencies');
    final list = resp['data'];
    if (list is! List) return [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> transfer({
    required String receiverPhone,
    required double amount,
    required String description,
    String? idempotencyKey,
  }) =>
      _client.post('/transactions/transfer', {
        'receiverPhone': receiverPhone,
        'amount': amount,
        'description': description,
        if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
      });

  Future<Map<String, dynamic>> deposit({
    required double amount,
    required String source,
    required String description,
    String? agentId,
    String? idempotencyKey,
  }) =>
      _client.post('/transactions/deposit', {
        'amount': amount,
        'source': source,
        'description': description,
        if (agentId != null) 'agentId': agentId,
        if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
      });

  Future<Map<String, dynamic>> withdraw({
    required double amount,
    required String channel,
    required String reference,
    String? phone,
    String? agentId,
    String? idempotencyKey,
  }) =>
      _client.post('/transactions/withdraw', {
        'amount': amount,
        'channel': channel,
        'reference': reference,
        if (phone != null) 'phone': phone,
        if (agentId != null) 'agentId': agentId,
        if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
      });

  Future<Map<String, dynamic>> buyAirtime({
    required String operatorName,
    required String phone,
    required double amount,
    String? idempotencyKey,
  }) =>
      _client.post('/transactions/airtime', {
        'operatorName': operatorName,
        'phone': phone,
        'amount': amount,
        if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
      });

  Future<Map<String, dynamic>> payTv({
    required String providerName,
    required String subscriberId,
    required String bouquetName,
    required double amount,
    String? idempotencyKey,
  }) =>
      _client.post('/transactions/tv', {
        'providerName': providerName,
        'subscriberId': subscriberId,
        'bouquetName': bouquetName,
        'amount': amount,
        if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
      });

  Future<Map<String, dynamic>> exchange({
    required String fromCurrency,
    required String toCurrency,
    required double amount,
    String? idempotencyKey,
  }) =>
      _client.post('/transactions/exchange', {
        'fromCurrency': fromCurrency,
        'toCurrency': toCurrency,
        'amount': amount,
        if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
      });

  Future<Map<String, dynamic>> payMerchant({
    required String merchant,
    required double amount,
    required String method,
    String? terminalLabel,
    String? location,
    String? idempotencyKey,
  }) =>
      _client.post('/transactions/merchant-pay', {
        'merchant': merchant,
        'amount': amount,
        'method': method,
        if (terminalLabel != null) 'terminalLabel': terminalLabel,
        if (location != null) 'location': location,
        if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
      });

  Future<Map<String, dynamic>> transferInternational({
    required String beneficiary,
    required String country,
    required double amount,
    required String reason,
    String? idempotencyKey,
  }) =>
      _client.post('/transactions/transfer-international', {
        'beneficiary': beneficiary,
        'country': country,
        'amount': amount,
        'reason': reason,
        if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
      });

  Future<Map<String, dynamic>> requestMoney({
    required double amount,
    String? targetPhone,
    String? targetId,
    String? reason,
    String? channel,
    String? idempotencyKey,
  }) =>
      _client.post('/transactions/request-money', {
        'amount': amount,
        if (targetPhone != null) 'targetPhone': targetPhone,
        if (targetId != null) 'targetId': targetId,
        if (reason != null) 'reason': reason,
        if (channel != null) 'channel': channel,
        if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
      });

  Future<List<Map<String, dynamic>>> fetchPendingApprovals() async {
    final resp = await _client.get('/transactions/pending-approvals');
    final list = resp['data'] ?? resp;
    if (list is! List) return [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> approveRequest(String id) =>
      _client.post('/transactions/$id/approve', {});

  Future<Map<String, dynamic>> rejectRequest(String id) =>
      _client.post('/transactions/$id/reject', {});
}
