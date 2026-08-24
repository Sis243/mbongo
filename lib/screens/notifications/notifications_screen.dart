import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../features/notifications/data/notifications_repository.dart';
import '../../features/notifications/presentation/notifications_provider.dart';
import '../../widgets/common/mbongo_sub_app_bar.dart';
import '../../widgets/common/mbongo_money_particles.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _icon(String type) {
    switch (type) {
      case 'CREDIT': return Icons.arrow_downward_rounded;
      case 'DEBIT': return Icons.arrow_upward_rounded;
      case 'TRANSFER_IN': return Icons.call_received_rounded;
      case 'TRANSFER_OUT': return Icons.call_made_rounded;
      case 'KYC_APPROVED': return Icons.verified_user_rounded;
      case 'KYC_REJECTED': return Icons.gpp_bad_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _iconColor(String type, MbongoThemePalette palette) {
    switch (type) {
      case 'CREDIT':
      case 'TRANSFER_IN':
      case 'KYC_APPROVED': return const Color(0xFF4CAF50);
      case 'DEBIT':
      case 'TRANSFER_OUT': return palette.accentStrong;
      case 'KYC_REJECTED': return const Color(0xFFC44040);
      default: return palette.accent;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} j';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = MbongoThemeController.current;
    final notifsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: palette.shellBottom,
      appBar: MbongoSubAppBar(
        title: 'Notifications',
        actions: [
          notifsAsync.whenOrNull(
            data: (r) {
              if (r.unread == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: () async {
                  await ref.read(notificationsRepositoryProvider).markAllRead();
                  ref.invalidate(notificationsProvider);
                },
                child: Text(
                  'Tout lire',
                  style: TextStyle(
                    color: palette.accentStrong,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              );
            },
          ),
        ].whereType<Widget>().toList(),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: MbongoMoneyParticles(
                color: palette.accent,
                count: 8,
                opacity: 0.05,
              ),
            ),
          ),
          notifsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('Erreur: $e',
                  style: const TextStyle(color: AppColors.muted)),
            ),
            data: (r) {
              final items = r.items;
              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_off_outlined,
                          size: 56, color: AppColors.muted),
                      const SizedBox(height: 12),
                      const Text('Aucune notification',
                          style: TextStyle(color: AppColors.muted, fontSize: 15)),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                color: palette.accent,
                onRefresh: () async => ref.invalidate(notificationsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: items.length,
                  itemBuilder: (ctx, i) {
                    final n = items[i];
                    final iconColor = _iconColor(n.type, palette);
                    return GestureDetector(
                      onTap: () async {
                        if (!n.isRead) {
                          await ref
                              .read(notificationsRepositoryProvider)
                              .markRead(n.id);
                          ref.invalidate(notificationsProvider);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: !n.isRead
                              ? palette.accent.withValues(alpha: 0.07)
                              : palette.panel,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: !n.isRead
                                ? palette.accent.withValues(alpha: 0.25)
                                : AppColors.border.withValues(alpha: 0.15),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: iconColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(_icon(n.type),
                                color: iconColor, size: 20),
                          ),
                          title: Text(
                            n.title,
                            style: TextStyle(
                              color: AppColors.text,
                              fontWeight: !n.isRead
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text(n.body,
                                  style: const TextStyle(
                                      color: AppColors.muted, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(
                                _timeAgo(n.createdAt),
                                style: TextStyle(
                                  color:
                                      palette.accent.withValues(alpha: 0.7),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          trailing: !n.isRead
                              ? Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: palette.accentStrong,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
