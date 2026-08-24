import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notifications_repository.dart';

final notificationsProvider =
    FutureProvider<({List<AppNotification> items, int unread})>((ref) async {
  return ref.read(notificationsRepositoryProvider).fetchInbox();
});

final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).whenOrNull(data: (r) => r.unread) ?? 0;
});
