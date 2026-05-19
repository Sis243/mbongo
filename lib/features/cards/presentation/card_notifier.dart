import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/card_repository.dart';

final cardProvider =
    AsyncNotifierProvider<CardNotifier, List<Map<String, dynamic>>>(
  CardNotifier.new,
);

class CardNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() => _load();

  Future<List<Map<String, dynamic>>> _load() async {
    try {
      return await ref.read(cardRepositoryProvider).fetchCards();
    } catch (_) {
      return [];
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _load());
  }

  Future<void> createCard({
    required String holderName,
    required String currency,
    required String brand,
  }) async {
    await ref.read(cardRepositoryProvider).createCard(
          holderName: holderName,
          currency: currency,
          brand: brand,
        );
    await refresh();
  }

  Future<void> topupCard({
    required String cardId,
    required double amount,
  }) async {
    await ref.read(cardRepositoryProvider).topupCard(
          cardId: cardId,
          amount: amount,
          idempotencyKey: DateTime.now().millisecondsSinceEpoch.toString(),
        );
    await refresh();
  }

  Future<void> toggleCard(String cardId) async {
    await ref.read(cardRepositoryProvider).toggleCard(cardId);
    await refresh();
  }
}
