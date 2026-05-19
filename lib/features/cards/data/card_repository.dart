import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_client.dart';

final cardRepositoryProvider = Provider<CardRepository>((ref) {
  return CardRepository(ref.read(dioClientProvider));
});

class CardRepository {
  final DioClient _client;
  const CardRepository(this._client);

  Future<List<Map<String, dynamic>>> fetchCards() async {
    final resp = await _client.get('/cards/me');
    final list = resp['data'];
    if (list is! List) return [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> createCard({
    required String holderName,
    required String currency,
    required String brand,
  }) =>
      _client.post('/cards', {
        'holderName': holderName,
        'currency': currency,
        'brand': brand,
      });

  Future<Map<String, dynamic>> topupCard({
    required String cardId,
    required double amount,
    String? idempotencyKey,
  }) =>
      _client.post('/cards/$cardId/topup', {
        'amount': amount,
        if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
      });

  Future<Map<String, dynamic>> toggleCard(String cardId) =>
      _client.patch('/cards/$cardId/toggle', {});
}
