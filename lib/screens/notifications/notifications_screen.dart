import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../features/notifications/data/notifications_repository.dart';
import '../../features/notifications/presentation/notifications_provider.dart';
import '../../widgets/common/mbongo_money_particles.dart';
import '../../widgets/common/mbongo_sub_app_bar.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = MbongoThemeController.current;
    final notifsAsync = ref.watch(notificationsProvider);
    final readIds = ref.watch(readNotificationIdsProvider);

    return Scaffold(
      backgroundColor: palette.shellBottom,
      appBar: MbongoSubAppBar(
        title: 'Notifications',
        actions: [
          notifsAsync.whenOrNull(
            data: (list) {
              final unread = list.where((n) => !readIds.contains(n.id)).toList();
              if (unread.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () {
                  ref
                      .read(readNotificationIdsProvider.notifier)
                      .markAllRead(list.map((n) => n.id).toList());
                },
                child: const Text(
                  'Tout lire',
                  style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700),
                ),
              );
            },
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.shellTop, palette.shellBottom],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: MbongoMoneyParticles(
                  color: palette.accent,
                  count: 14,
                  opacity: 0.07,
                  height: 0,
                ),
              ),
            ),
            SafeArea(
              child: notifsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded, color: AppColors.muted, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Impossible de charger les notifications.',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.refresh(notificationsProvider),
                        child: const Text('Reessayer'),
                      ),
                    ],
                  ),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return _buildEmpty(palette);
                  }
                  return RefreshIndicator(
                    onRefresh: () => ref.refresh(notificationsProvider.future),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final n = list[i];
                        final isRead = readIds.contains(n.id);
                        return _NotificationTile(
                          notification: n,
                          isRead: isRead,
                          onTap: () {
                            ref.read(readNotificationIdsProvider.notifier).markRead(n.id);
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(MbongoThemePalette palette) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: palette.panelAlt,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 52,
                color: palette.accent.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aucune notification',
              style: TextStyle(
                color: AppColors.darkText,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vous serez notifie ici de toutes les activites importantes sur votre compte.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.darkMuted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final bool isRead;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.isRead,
    required this.onTap,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return "A l'instant";
    if (diff.inHours < 1) return 'Il y a ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'Il y a ${diff.inHours}h';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  IconData _channelIcon(String channel) {
    switch (channel.toUpperCase()) {
      case 'PUSH':
        return Icons.notifications_active_rounded;
      case 'EMAIL':
        return Icons.email_rounded;
      case 'SMS':
        return Icons.sms_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isRead ? palette.panelAlt : const Color(0xFF102A55),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isRead
                    ? AppColors.border.withValues(alpha: 0.24)
                    : palette.accent.withValues(alpha: 0.5),
                width: isRead ? 1 : 1.4,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: palette.accent.withValues(alpha: isRead ? 0.10 : 0.20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _channelIcon(notification.channel),
                    color: isRead ? palette.accent : Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                color: isRead ? AppColors.darkText : Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: palette.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: TextStyle(
                          color: isRead ? AppColors.darkMuted : const Color(0xFFB8CDE8),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatDate(notification.createdAt),
                        style: TextStyle(
                          color: isRead
                              ? AppColors.darkMuted
                              : const Color(0xFF8AABC8),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
