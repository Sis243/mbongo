import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_client.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.read(dioClientProvider));
});

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String channel;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.channel,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> m) => AppNotification(
        id: m['id']?.toString() ?? '',
        title: m['title']?.toString() ?? '',
        body: m['body']?.toString() ?? '',
        channel: m['channel']?.toString() ?? 'IN_APP',
        createdAt: DateTime.tryParse(m['createdAt']?.toString() ?? '') ?? DateTime.now(),
      );
}

class NotificationsRepository {
  final DioClient _client;
  const NotificationsRepository(this._client);

  Future<List<AppNotification>> fetchMyNotifications() async {
    final resp = await _client.get('/notifications/me');
    final list = resp['data'];
    if (list is! List) return [];
    return list
        .map((e) => AppNotification.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
