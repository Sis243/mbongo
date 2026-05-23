import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/notifications_repository.dart';

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  return ref.read(notificationsRepositoryProvider).fetchMyNotifications();
});

// Locally-stored set of read notification IDs
final readNotificationIdsProvider =
    StateNotifierProvider<ReadNotificationsNotifier, Set<String>>(
  (ref) => ReadNotificationsNotifier(),
);

class ReadNotificationsNotifier extends StateNotifier<Set<String>> {
  static const _key = 'mbongo_read_notification_ids';

  ReadNotificationsNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key) ?? [];
    state = ids.toSet();
  }

  Future<void> markRead(String id) async {
    final next = {...state, id};
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next.toList());
  }

  Future<void> markAllRead(List<String> ids) async {
    final next = {...state, ...ids};
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next.toList());
  }
}

// Unread count badge
final unreadCountProvider = Provider<AsyncValue<int>>((ref) {
  final notifs = ref.watch(notificationsProvider);
  final readIds = ref.watch(readNotificationIdsProvider);
  return notifs.whenData(
    (list) => list.where((n) => !readIds.contains(n.id)).length,
  );
});
