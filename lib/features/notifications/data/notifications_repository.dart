import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_client.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.read(dioClientProvider));
});

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> m) => AppNotification(
        id: m['id']?.toString() ?? '',
        title: m['title']?.toString() ?? '',
        body: m['body']?.toString() ?? '',
        type: m['type']?.toString() ?? 'SYSTEM',
        isRead: m['readAt'] != null,
        createdAt: DateTime.tryParse(m['createdAt']?.toString() ?? '') ?? DateTime.now(),
      );
}

class NotificationsRepository {
  final DioClient _client;
  const NotificationsRepository(this._client);

  Future<({List<AppNotification> items, int unread})> fetchInbox({int page = 1}) async {
    final resp = await _client.get('/inbox?page=$page');
    final list = resp['items'];
    final items = list is List
        ? list.map((e) => AppNotification.fromMap(Map<String, dynamic>.from(e as Map))).toList()
        : <AppNotification>[];
    return (items: items, unread: (resp['unread'] as num?)?.toInt() ?? 0);
  }

  Future<void> markRead(String id) => _client.patch('/inbox/$id/read', {});
  Future<void> markAllRead() => _client.patch('/inbox/read-all', {});
}
