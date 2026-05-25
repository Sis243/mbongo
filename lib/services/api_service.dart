import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'auth_service.dart';

class ApiException implements Exception {
  final String message;

  const ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  static String get _baseUrl {
    const configured = String.fromEnvironment('MBONGO_API_BASE_URL');
    if (configured.isNotEmpty) return configured;
    return 'https://mbongo-backend.vercel.app';
  }

  static Future<Map<String, dynamic>> login({
    required String phone,
    required String pin,
  }) async {
    return _post(
      '/auth/login',
      body: {
        'phone': phone,
        'pin': pin,
      },
    );
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String pin,
  }) async {
    return _post(
      '/auth/register',
      body: {
        'name': name,
        'phone': phone,
        'pin': pin,
      },
    );
  }

  static Future<Map<String, dynamic>> refreshSession() async {
    final refreshToken = await AuthService.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const ApiException('Aucune session a rafraichir');
    }

    return _post(
      '/auth/refresh',
      body: {
        'refreshToken': refreshToken,
      },
    );
  }

  static Future<void> logoutSession() async {
    final refreshToken = await AuthService.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return;
    }

    await _post(
      '/auth/logout',
      body: {
        'refreshToken': refreshToken,
      },
    );
  }

  static Future<Map<String, dynamic>> getUser(String userId) async {
    return _get('/users/me');
  }

  static Future<Map<String, dynamic>> getKycStatus() async {
    return _get('/kyc/me');
  }

  static Future<Map<String, dynamic>> requestOtp(String phone, {String purpose = 'login'}) {
    return _post('/otp/request', body: {'phone': phone, 'purpose': purpose});
  }

  static Future<Map<String, dynamic>> verifyOtp(String phone, String code, {String purpose = 'login'}) {
    return _post('/otp/verify', body: {'phone': phone, 'code': code, 'purpose': purpose});
  }

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
      final resolvedFront = frontExists ? frontFile : null;
      final resolvedBack = backExists ? backFile : null;
      final resolvedSelfie = selfieExists ? selfieFile : null;

      // Vérifier la taille totale — Vercel limite à 4.5 MB
      const maxTotalBytes = 4 * 1024 * 1024; // 4 MB marge de sécurité
      int totalBytes = 0;
      for (final f in [resolvedFront, resolvedBack, resolvedSelfie]) {
        if (f != null) totalBytes += await f.length();
      }
      if (totalBytes > maxTotalBytes) {
        throw const ApiException(
          'Les fichiers KYC sont trop volumineux (max 4 MB au total). Utilisez des images plus petites.',
        );
      }

      return _postKycMultipart(
        documentType: documentType,
        frontFile: resolvedFront,
        backFile: resolvedBack,
        selfieFile: resolvedSelfie,
      );
    }

    return _post(
      '/kyc/me/submit',
      body: {
        'documentType': documentType,
        'frontUrl': frontPath,
        'backUrl': backPath,
        'selfieUrl': selfiePath,
      },
    );
  }

  static Future<Map<String, dynamic>> _postKycMultipart({
    required String documentType,
    File? frontFile,
    File? backFile,
    File? selfieFile,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 30)
      ..idleTimeout = const Duration(seconds: 60);
    final boundary = 'mbongo-${DateTime.now().microsecondsSinceEpoch}';
    final body = BytesBuilder();

    void addTextField(String name, String value) {
      body.add(utf8.encode('--$boundary\r\n'));
      body.add(
          utf8.encode('Content-Disposition: form-data; name="$name"\r\n\r\n'));
      body.add(utf8.encode('$value\r\n'));
    }

    Future<void> addFileField(String name, File file) async {
      final fileName = file.uri.pathSegments.isNotEmpty
          ? file.uri.pathSegments.last
          : '$name.jpg';
      body.add(utf8.encode('--$boundary\r\n'));
      body.add(
        utf8.encode(
          'Content-Disposition: form-data; name="$name"; filename="$fileName"\r\n',
        ),
      );
      body.add(utf8.encode('Content-Type: ${_mimeTypeFor(fileName)}\r\n\r\n'));
      body.add(await file.readAsBytes());
      body.add(utf8.encode('\r\n'));
    }

    try {
      addTextField('documentType', documentType);
      if (frontFile != null) await addFileField('front', frontFile);
      if (backFile != null) await addFileField('back', backFile);
      if (selfieFile != null) await addFileField('selfie', selfieFile);
      body.add(utf8.encode('--$boundary--\r\n'));

      final bytes = body.takeBytes();
      final request =
          await client.postUrl(Uri.parse('$_baseUrl/kyc/me/submit-upload'));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.contentTypeHeader,
          'multipart/form-data; boundary=$boundary');
      request.contentLength = bytes.length;

      final token = await AuthService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }

      request.add(bytes);
      final response = await request.close();
      final decoded = await _decodeResponse(response);

      if (response.statusCode >= 400) {
        throw ApiException(
            _extractMessage(decoded, fallback: 'Envoi KYC impossible'));
      }

      return Map<String, dynamic>.from(decoded as Map);
    } on SocketException {
      throw const ApiException(
          'API Mbongo inaccessible. Verifiez que le backend tourne.');
    } finally {
      client.close();
    }
  }

  static String _mimeTypeFor(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    return 'image/jpeg';
  }

  static Future<Map<String, dynamic>> getWalletSummary(String userId) async {
    return _get('/wallet/me');
  }

  static Future<List<Map<String, dynamic>>> getWalletLedger(
      String userId) async {
    final response = await _get('/wallet/me/ledger');
    final list = response['data'];
    if (list is List) {
      return list
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    return [];
  }

  static Future<List<Map<String, dynamic>>> getTransactions(
      String userId) async {
    final response = await _get('/transactions');
    final list = response['data'];
    if (list is List) {
      return list
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    return [];
  }

  static Future<List<Map<String, dynamic>>> getCashAgents() async {
    final response = await _get('/transactions/cash-agents');
    final list = response['data'];
    if (list is List) {
      return list
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    return [];
  }

  static Future<Map<String, dynamic>> getAgentProfitLog() async {
    final response = await _get('/transactions/agent/profit-log');
    final data = response['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return response;
  }

  static Future<Map<String, dynamic>> transfer({
    required String senderId,
    required String receiverPhone,
    required double amount,
    required String description,
    String? idempotencyKey,
  }) async {
    return _post(
      '/transactions/transfer',
      body: {
        'senderId': senderId,
        'receiverPhone': receiverPhone,
        'amount': amount,
        'description': description,
        'idempotencyKey': idempotencyKey,
      },
    );
  }

  static Future<Map<String, dynamic>> deposit({
    required String userId,
    required double amount,
    required String source,
    required String description,
    String? agentName,
    String? agentId,
    String? idempotencyKey,
  }) async {
    return _post(
      '/transactions/deposit',
      body: {
        'userId': userId,
        'amount': amount,
        'source': source,
        'description': description,
        'agentName': agentName,
        'agentId': agentId,
        'idempotencyKey': idempotencyKey,
      },
    );
  }

  static Future<Map<String, dynamic>> withdraw({
    required String userId,
    required double amount,
    required String channel,
    required String reference,
    String? phone,
    String? agentName,
    String? agentId,
    String? idempotencyKey,
  }) async {
    return _post(
      '/transactions/withdraw',
      body: {
        'userId': userId,
        'amount': amount,
        'channel': channel,
        'reference': reference,
        'phone': phone,
        'agentName': agentName,
        'agentId': agentId,
        'idempotencyKey': idempotencyKey,
      },
    );
  }

  static Future<Map<String, dynamic>> buyAirtime({
    required String userId,
    required String operatorName,
    required String phone,
    required double amount,
    String? idempotencyKey,
  }) async {
    return _post(
      '/transactions/airtime',
      body: {
        'userId': userId,
        'operatorName': operatorName,
        'phone': phone,
        'amount': amount,
        'idempotencyKey': idempotencyKey,
      },
    );
  }

  static Future<Map<String, dynamic>> payTv({
    required String userId,
    required String providerName,
    required String subscriberId,
    required String bouquetName,
    required double amount,
    String? idempotencyKey,
  }) async {
    return _post(
      '/transactions/tv',
      body: {
        'userId': userId,
        'providerName': providerName,
        'subscriberId': subscriberId,
        'bouquetName': bouquetName,
        'amount': amount,
        'idempotencyKey': idempotencyKey,
      },
    );
  }

  static Future<Map<String, dynamic>> payMerchant({
    required String userId,
    required String merchant,
    required double amount,
    required String method,
    String? terminalLabel,
    String? location,
    String? idempotencyKey,
  }) async {
    return _post(
      '/transactions/merchant-pay',
      body: {
        'userId': userId,
        'merchant': merchant,
        'amount': amount,
        'method': method,
        'terminalLabel': terminalLabel,
        'location': location,
        'idempotencyKey': idempotencyKey,
      },
    );
  }

  static Future<List<Map<String, dynamic>>> getVirtualCards(
      String userId) async {
    final response = await _get('/cards/me');
    final list = response['data'];
    if (list is List) {
      return list
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    return [];
  }

  static Future<Map<String, dynamic>> createVirtualCard({
    required String userId,
    required String holderName,
    required String currency,
    required String brand,
  }) async {
    return _post(
      '/cards',
      body: {
        'userId': userId,
        'holderName': holderName,
        'currency': currency,
        'brand': brand,
      },
    );
  }

  static Future<Map<String, dynamic>> topupVirtualCard({
    required String userId,
    required String cardId,
    required double amount,
    String? idempotencyKey,
  }) async {
    return _post(
      '/cards/$cardId/topup',
      body: {
        'userId': userId,
        'amount': amount,
        'idempotencyKey': idempotencyKey,
      },
    );
  }

  static Future<Map<String, dynamic>> toggleVirtualCardStatus({
    required String userId,
    required String cardId,
  }) async {
    return _patch(
      '/cards/$cardId/toggle',
      body: {
        'userId': userId,
      },
    );
  }

  static Future<List<Map<String, dynamic>>> getCurrencies() async {
    final response = await _get('/merchant/currencies');
    final list = response['data'];
    if (list is List) {
      return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getMerchantAccounts() async {
    final response = await _get('/merchant/accounts');
    final list = response['data'];
    if (list is List) {
      return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> getMyMerchantProfile() async {
    final response = await _get('/merchant/me');
    final data = response['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return response;
  }

  static Future<List<Map<String, dynamic>>> getMerchantTerminals() async {
    final response = await _get('/merchant/terminals');
    final list = response['data'];
    if (list is List) {
      return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getMerchantReceipts() async {
    final response = await _get('/merchant/receipts');
    final list = response['data'];
    if (list is List) {
      return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> getMerchantReceipt(String id) async {
    return _get('/merchant/receipts/$id');
  }

  static Future<List<Map<String, dynamic>>> getMerchantRoles() async {
    final response = await _get('/merchant/roles');
    final list = response['data'];
    if (list is List) {
      return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> _get(
    String path, {
    bool authenticated = true,
  }) async {
    final client = HttpClient();

    try {
      final request = await client.getUrl(Uri.parse('$_baseUrl$path'));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      if (authenticated) {
        final token = await AuthService.getAccessToken();
        if (token != null && token.isNotEmpty) {
          request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
        }
      }

      final response = await request.close();
      final decoded = await _decodeResponse(response);

      if (response.statusCode >= 400) {
        throw ApiException(_extractMessage(decoded, fallback: 'Erreur API'));
      }

      return _mapResponse(decoded);
    } on SocketException {
      throw const ApiException(
          'API Mbongo inaccessible. Verifiez que le backend tourne.');
    } finally {
      client.close();
    }
  }

  static Future<Map<String, dynamic>> _post(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final client = HttpClient();

    try {
      final request = await client.postUrl(Uri.parse('$_baseUrl$path'));
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final token = await AuthService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      request.write(jsonEncode(body));

      final response = await request.close();
      final decoded = await _decodeResponse(response);

      if (response.statusCode >= 400) {
        throw ApiException(_extractMessage(decoded, fallback: 'Erreur API'));
      }

      return _mapResponse(decoded);
    } on SocketException {
      throw const ApiException(
          'API Mbongo inaccessible. Verifiez que le backend tourne.');
    } finally {
      client.close();
    }
  }

  static Future<Map<String, dynamic>> _patch(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final client = HttpClient();

    try {
      final request = await client.patchUrl(Uri.parse('$_baseUrl$path'));
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final token = await AuthService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      request.write(jsonEncode(body));

      final response = await request.close();
      final decoded = await _decodeResponse(response);

      if (response.statusCode >= 400) {
        throw ApiException(_extractMessage(decoded, fallback: 'Erreur API'));
      }

      return _mapResponse(decoded);
    } on SocketException {
      throw const ApiException(
          'API Mbongo inaccessible. Verifiez que le backend tourne.');
    } finally {
      client.close();
    }
  }

  static Future<dynamic> _decodeResponse(HttpClientResponse response) async {
    final raw = await response.transform(utf8.decoder).join();
    if (raw.isEmpty) {
      return <String, dynamic>{};
    }

    return jsonDecode(raw);
  }

  static Map<String, dynamic> _mapResponse(dynamic decoded) {
    if (decoded == null) {
      return <String, dynamic>{};
    }

    if (decoded is List) {
      return {'data': decoded};
    }

    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    return {'data': decoded};
  }

  static String _extractMessage(dynamic decoded, {required String fallback}) {
    if (decoded is Map<String, dynamic>) {
      final message = decoded['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }

      if (message is List && message.isNotEmpty) {
        return message.join(', ');
      }
    }

    return fallback;
  }
}
