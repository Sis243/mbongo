import 'dart:io' show File;

import '../core/api/dio_client.dart';
import '../core/storage/app_storage.dart';

export '../core/api/dio_client.dart' show ApiException;

// Static facade over DioClient — tous les appels passent par Dio
// avec token refresh automatique et retry sur 5xx.
class ApiService {
  static final DioClient _client = DioClient(AppStorage());

  static Stream<void> get sessionExpiredStream => DioClient.sessionExpiredStream;

  // ── Auth (sans token) ────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> login({
    required String phone,
    required String pin,
  }) =>
      _client.post('/auth/login', {'phone': phone, 'pin': pin}, auth: false);

  static Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String pin,
  }) =>
      _client.post('/auth/register', {'name': name, 'phone': phone, 'pin': pin}, auth: false);

  static Future<Map<String, dynamic>> requestOtp(String phone, {String purpose = 'login'}) =>
      _client.post('/otp/request', {'phone': phone, 'purpose': purpose}, auth: false);

  static Future<Map<String, dynamic>> verifyOtp(String phone, String code, {String purpose = 'login'}) =>
      _client.post('/otp/verify', {'phone': phone, 'code': code, 'purpose': purpose}, auth: false);

  static Future<Map<String, dynamic>> resetPin(String phone, String code, String newPin) =>
      _client.post('/auth/reset-pin', {'phone': phone, 'code': code, 'newPin': newPin}, auth: false);

  // ── User ─────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getUser(String userId) => _client.get('/users/me');

  static Future<Map<String, dynamic>> getKycStatus() => _client.get('/kyc/me');

  static Future<String?> getBackupPhone() async {
    try {
      final r = await _client.get('/users/me/backup-phone');
      return r['backupPhone'] as String?;
    } catch (_) {
      return null;
    }
  }

  static Future<void> updateBackupPhone(String phone) =>
      _client.patch('/users/me/backup-phone', {'backupPhone': phone});

  // ── App version ──────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getAppVersion() async {
    try {
      return await _client.get('/app/version');
    } catch (_) {
      return {};
    }
  }

  // ── Wallet & transactions ────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getWalletSummary(String userId) =>
      _client.get('/wallet/me');

  static Future<List<Map<String, dynamic>>> getWalletLedger(String userId) async {
    final r = await _client.get('/wallet/me/ledger');
    return _toList(r['data']);
  }

  static Future<List<Map<String, dynamic>>> getTransactions(String userId) async {
    final r = await _client.get('/transactions');
    return _toList(r['data']);
  }

  static Future<List<Map<String, dynamic>>> getCashAgents() async {
    final r = await _client.get('/transactions/cash-agents');
    return _toList(r['data']);
  }

  static Future<Map<String, dynamic>> getAgentProfitLog() async {
    final r = await _client.get('/transactions/agent/profit-log');
    final data = r['data'];
    return data is Map ? Map<String, dynamic>.from(data) : r;
  }

  static Future<Map<String, dynamic>> transfer({
    required String senderId,
    required String receiverPhone,
    required double amount,
    required String description,
    String? idempotencyKey,
  }) =>
      _client.post('/transactions/transfer', {
        'senderId': senderId,
        'receiverPhone': receiverPhone,
        'amount': amount,
        'description': description,
        'idempotencyKey': idempotencyKey,
      });

  static Future<Map<String, dynamic>> deposit({
    required String userId,
    required double amount,
    required String source,
    required String description,
    String? agentName,
    String? agentId,
    String? idempotencyKey,
  }) =>
      _client.post('/transactions/deposit', {
        'userId': userId,
        'amount': amount,
        'source': source,
        'description': description,
        'agentName': agentName,
        'agentId': agentId,
        'idempotencyKey': idempotencyKey,
      });

  static Future<Map<String, dynamic>> withdraw({
    required String userId,
    required double amount,
    required String channel,
    required String reference,
    String? phone,
    String? agentName,
    String? agentId,
    String? idempotencyKey,
  }) =>
      _client.post('/transactions/withdraw', {
        'userId': userId,
        'amount': amount,
        'channel': channel,
        'reference': reference,
        'phone': phone,
        'agentName': agentName,
        'agentId': agentId,
        'idempotencyKey': idempotencyKey,
      });

  static Future<Map<String, dynamic>> buyAirtime({
    required String userId,
    required String operatorName,
    required String phone,
    required double amount,
    String? idempotencyKey,
  }) =>
      _client.post('/transactions/airtime', {
        'userId': userId,
        'operatorName': operatorName,
        'phone': phone,
        'amount': amount,
        'idempotencyKey': idempotencyKey,
      });

  static Future<Map<String, dynamic>> payTv({
    required String userId,
    required String providerName,
    required String subscriberId,
    required String bouquetName,
    required double amount,
    String? idempotencyKey,
  }) =>
      _client.post('/transactions/tv', {
        'userId': userId,
        'providerName': providerName,
        'subscriberId': subscriberId,
        'bouquetName': bouquetName,
        'amount': amount,
        'idempotencyKey': idempotencyKey,
      });

  static Future<Map<String, dynamic>> payMerchant({
    required String userId,
    required String merchant,
    required double amount,
    required String method,
    String? terminalLabel,
    String? location,
    String? idempotencyKey,
  }) =>
      _client.post('/transactions/merchant-pay', {
        'userId': userId,
        'merchant': merchant,
        'amount': amount,
        'method': method,
        'terminalLabel': terminalLabel,
        'location': location,
        'idempotencyKey': idempotencyKey,
      });

  static Future<Map<String, dynamic>> getBillPayMethods() => _client.get('/bill-pay/methods');

  static Future<Map<String, dynamic>> payBill({
    required String methodId,
    required String methodName,
    required String reference,
    required double amount,
    String? idempotencyKey,
  }) =>
      _client.post('/transactions/bill-pay', {
        'methodId': methodId,
        'methodName': methodName,
        'reference': reference,
        'amount': amount,
        'idempotencyKey': idempotencyKey,
      });

  // ── KYC ─────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> submitKyc({
    required String documentType,
    required String frontPath,
    required String backPath,
    required String selfiePath,
  }) async {
    final frontFile = File(frontPath);
    final backFile = File(backPath);
    final selfieFile = File(selfiePath);

    final frontExists = await frontFile.exists();
    final backExists = await backFile.exists();
    final selfieExists = await selfieFile.exists();

    if (frontExists || backExists || selfieExists) {
      const maxTotalBytes = 4 * 1024 * 1024;
      int total = 0;
      for (final f in [
        if (frontExists) frontFile,
        if (backExists) backFile,
        if (selfieExists) selfieFile,
      ]) {
        total += await f.length();
      }
      if (total > maxTotalBytes) {
        throw const ApiException(
          'Les fichiers KYC sont trop volumineux (max 4 MB au total). Utilisez des images plus petites.',
        );
      }

      return _client.postMultipart(
        '/kyc/me/submit-upload',
        fields: {'documentType': documentType},
        files: {
          if (frontExists) 'front': frontFile,
          if (backExists) 'back': backFile,
          if (selfieExists) 'selfie': selfieFile,
        },
      );
    }

    return _client.post('/kyc/me/submit', {
      'documentType': documentType,
      'frontUrl': frontPath,
      'backUrl': backPath,
      'selfieUrl': selfiePath,
    });
  }

  // ── Virtual cards ────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getVirtualCards(String userId) async {
    final r = await _client.get('/cards/me');
    return _toList(r['data']);
  }

  static Future<Map<String, dynamic>> createVirtualCard({
    required String userId,
    required String holderName,
    required String currency,
    required String brand,
  }) =>
      _client.post('/cards', {'userId': userId, 'holderName': holderName, 'currency': currency, 'brand': brand});

  static Future<Map<String, dynamic>> topupVirtualCard({
    required String userId,
    required String cardId,
    required double amount,
    String? idempotencyKey,
  }) =>
      _client.post('/cards/$cardId/topup', {'userId': userId, 'amount': amount, 'idempotencyKey': idempotencyKey});

  static Future<Map<String, dynamic>> toggleVirtualCardStatus({
    required String userId,
    required String cardId,
  }) =>
      _client.patch('/cards/$cardId/toggle', {'userId': userId});

  // ── Merchant ─────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getCurrencies() async {
    final r = await _client.get('/merchant/currencies');
    return _toList(r['data']);
  }

  static Future<List<Map<String, dynamic>>> getMerchantAccounts() async {
    final r = await _client.get('/merchant/accounts');
    return _toList(r['data']);
  }

  static Future<Map<String, dynamic>> getMyMerchantProfile() async {
    final r = await _client.get('/merchant/me');
    final data = r['data'];
    return data is Map ? Map<String, dynamic>.from(data) : r;
  }

  static Future<List<Map<String, dynamic>>> getMerchantTerminals() async {
    final r = await _client.get('/merchant/terminals');
    return _toList(r['data']);
  }

  static Future<List<Map<String, dynamic>>> getMerchantReceipts() async {
    final r = await _client.get('/merchant/receipts');
    return _toList(r['data']);
  }

  static Future<Map<String, dynamic>> getMerchantReceipt(String id) =>
      _client.get('/merchant/receipts/$id');

  static Future<List<Map<String, dynamic>>> getMerchantRoles() async {
    final r = await _client.get('/merchant/roles');
    return _toList(r['data']);
  }

  // ── Core Banking ─────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> lookupBankAccount(String accountNumber) async {
    try {
      return await _client.get('/bank/lookup?accountNumber=${Uri.encodeComponent(accountNumber)}');
    } catch (_) {
      return {'exists': false};
    }
  }

  static Future<Map<String, dynamic>> linkBankAccount(String accountNumber) =>
      _client.post('/bank/link', {'accountNumber': accountNumber});

  static Future<List<Map<String, dynamic>>> getLinkedBankAccounts() async {
    try {
      final r = await _client.get('/bank/linked');
      return _toList(r['data']);
    } catch (_) {
      return [];
    }
  }

  static Future<void> unlinkBankAccount(String id) => _client.delete('/bank/linked/$id');

  static Future<Map<String, dynamic>> walletToAccount({
    required String accountId,
    required double amount,
  }) =>
      _client.post('/transactions/wallet-to-account', {'accountId': accountId, 'amount': amount});

  static Future<Map<String, dynamic>> accountToWallet({
    required String accountId,
    required double amount,
  }) =>
      _client.post('/transactions/account-to-wallet', {'accountId': accountId, 'amount': amount});

  // ── Helpers ──────────────────────────────────────────────────────────────

  static List<Map<String, dynamic>> _toList(dynamic value) {
    if (value is! List) return [];
    return value.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
