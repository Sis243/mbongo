import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/common/app_scaffold.dart';
import 'support_ticket_screen.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class SupportTicket {
  final String id;
  final String subject;
  final String status;
  final DateTime updatedAt;
  final String? lastMessage;

  const SupportTicket({
    required this.id,
    required this.subject,
    required this.status,
    required this.updatedAt,
    this.lastMessage,
  });

  factory SupportTicket.fromMap(Map<String, dynamic> m) {
    final msgs = m['messages'];
    String? last;
    if (msgs is List && msgs.isNotEmpty) {
      last = msgs.first['content']?.toString();
    }
    return SupportTicket(
      id: m['id']?.toString() ?? '',
      subject: m['subject']?.toString() ?? '',
      status: m['status']?.toString() ?? 'OPEN',
      updatedAt: DateTime.tryParse(m['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      lastMessage: last,
    );
  }

  Color statusColor(MbongoThemePalette p) => switch (status) {
        'OPEN' => const Color(0xFF4CAF50),
        'IN_PROGRESS' => p.accentStrong,
        _ => AppColors.muted,
      };

  String statusLabel() => switch (status) {
        'OPEN' => 'Ouvert',
        'IN_PROGRESS' => 'En cours',
        _ => 'Fermé',
      };
}

// ── Provider ──────────────────────────────────────────────────────────────────

final _ticketsProvider = FutureProvider<List<SupportTicket>>((ref) async {
  final r = await ApiService.getSupportTickets();
  final list = r['tickets'];
  if (list is! List) return [];
  return list
      .map((e) => SupportTicket.fromMap(Map<String, dynamic>.from(e as Map)))
      .toList();
});

// ── Screen ────────────────────────────────────────────────────────────────────

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  bool _showForm = false;
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final subject = _subjectCtrl.text.trim();
    final message = _messageCtrl.text.trim();
    if (subject.isEmpty || message.isEmpty) {
      setState(() => _error = 'Objet et message requis');
      return;
    }
    setState(() { _sending = true; _error = null; });
    try {
      final r = await ApiService.createSupportTicket(subject: subject, message: message);
      final id = r['id']?.toString() ?? '';
      _subjectCtrl.clear();
      _messageCtrl.clear();
      setState(() { _showForm = false; _sending = false; });
      ref.invalidate(_ticketsProvider);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SupportTicketScreen(ticketId: id, subject: subject)),
      );
      ref.invalidate(_ticketsProvider);
    } catch (e) {
      setState(() { _error = e.toString(); _sending = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    final ticketsAsync = ref.watch(_ticketsProvider);

    return MbongoPageScaffold(
      title: 'Support',
      primaryParticleColor: AppColors.gold,
      secondaryParticleColor: AppColors.primary,
      particleDensity: 0.8,
      child: Column(
        children: [
          // ── Nouveau ticket button ────────────────────────────────────────
          if (!_showForm)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => setState(() { _showForm = true; _error = null; }),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nouveau ticket'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.accentStrong,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
              ),
            ),

          // ── Formulaire nouveau ticket ────────────────────────────────────
          if (_showForm)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.panel,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.accent.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Nouveau ticket',
                          style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w900, fontSize: 15)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.muted),
                        onPressed: () => setState(() { _showForm = false; _error = null; }),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _field(palette, _subjectCtrl, 'Objet', 1),
                  const SizedBox(height: 10),
                  _field(palette, _messageCtrl, 'Décrivez votre problème…', 5),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(color: AppColors.red, fontSize: 12)),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _sending ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.accentStrong,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _sending
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Text('Envoyer', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),

          // ── Liste des tickets ────────────────────────────────────────────
          Expanded(
            child: ticketsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e', style: const TextStyle(color: AppColors.muted))),
              data: (tickets) {
                if (tickets.isEmpty && !_showForm) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.support_agent_rounded, size: 56, color: AppColors.muted),
                        const SizedBox(height: 12),
                        const Text('Aucun ticket pour l\'instant',
                            style: TextStyle(color: AppColors.muted, fontSize: 14)),
                        const SizedBox(height: 6),
                        const Text('Appuyez sur "Nouveau ticket" pour contacter le support',
                            style: TextStyle(color: AppColors.muted, fontSize: 12),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  color: palette.accent,
                  onRefresh: () async => ref.invalidate(_ticketsProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: tickets.length,
                    itemBuilder: (ctx, i) {
                      final t = tickets[i];
                      return GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SupportTicketScreen(ticketId: t.id, subject: t.subject),
                            ),
                          );
                          ref.invalidate(_ticketsProvider);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: palette.panel,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: t.statusColor(palette).withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.support_agent_rounded, color: t.statusColor(palette), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(t.subject,
                                        style: const TextStyle(
                                            color: AppColors.text, fontWeight: FontWeight.w800, fontSize: 13.5),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    if (t.lastMessage != null) ...[
                                      const SizedBox(height: 3),
                                      Text(t.lastMessage!,
                                          style: const TextStyle(color: AppColors.muted, fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: t.statusColor(palette).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(t.statusLabel(),
                                        style: TextStyle(
                                            color: t.statusColor(palette),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800)),
                                  ),
                                  const SizedBox(height: 4),
                                  Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 18),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(MbongoThemePalette palette, TextEditingController ctrl, String hint, int maxLines) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.text, fontSize: 13.5),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
        filled: true,
        fillColor: palette.panelAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: palette.accent.withValues(alpha: 0.6)),
        ),
      ),
    );
  }
}
