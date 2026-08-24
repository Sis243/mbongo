import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../services/api_service.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class _Message {
  final String id;
  final String content;
  final String authorType; // 'USER' | 'ADMIN'
  final DateTime createdAt;

  const _Message({
    required this.id,
    required this.content,
    required this.authorType,
    required this.createdAt,
  });

  bool get isUser => authorType == 'USER';

  factory _Message.fromMap(Map<String, dynamic> m) => _Message(
        id: m['id']?.toString() ?? '',
        content: m['content']?.toString() ?? '',
        authorType: m['authorType']?.toString() ?? 'USER',
        createdAt: DateTime.tryParse(m['createdAt']?.toString() ?? '') ?? DateTime.now(),
      );
}

class _TicketDetail {
  final String id;
  final String subject;
  final String status;
  final List<_Message> messages;

  const _TicketDetail({
    required this.id,
    required this.subject,
    required this.status,
    required this.messages,
  });

  factory _TicketDetail.fromMap(Map<String, dynamic> m) {
    final rawMsgs = m['messages'];
    final msgs = rawMsgs is List
        ? rawMsgs
            .map((e) => _Message.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList()
        : <_Message>[];
    msgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return _TicketDetail(
      id: m['id']?.toString() ?? '',
      subject: m['subject']?.toString() ?? '',
      status: m['status']?.toString() ?? 'OPEN',
      messages: msgs,
    );
  }

  bool get isClosed => status == 'CLOSED';
}

// ── Screen ────────────────────────────────────────────────────────────────────

class SupportTicketScreen extends ConsumerStatefulWidget {
  final String ticketId;
  final String subject;

  const SupportTicketScreen({
    super.key,
    required this.ticketId,
    required this.subject,
  });

  @override
  ConsumerState<SupportTicketScreen> createState() => _SupportTicketScreenState();
}

class _SupportTicketScreenState extends ConsumerState<SupportTicketScreen> {
  _TicketDetail? _ticket;
  bool _loading = true;
  String? _error;

  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await ApiService.getSupportTicket(widget.ticketId);
      setState(() {
        _ticket = _TicketDetail.fromMap(r);
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final content = _msgCtrl.text.trim();
    if (content.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ApiService.addSupportMessage(widget.ticketId, content);
      _msgCtrl.clear();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.red),
        );
      }
      setState(() => _sending = false);
    }
  }

  Future<void> _closeTicket() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Fermer le ticket', style: TextStyle(color: AppColors.text)),
        content: const Text('Confirmer la fermeture de ce ticket ?',
            style: TextStyle(color: AppColors.muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Fermer', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.closeSupportTicket(widget.ticketId);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    final ticket = _ticket;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.text, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.subject,
                style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w800, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            if (ticket != null)
              Text(_statusLabel(ticket.status),
                  style: TextStyle(color: _statusColor(ticket.status), fontSize: 11)),
          ],
        ),
        actions: [
          if (ticket != null && !ticket.isClosed)
            IconButton(
              icon: const Icon(Icons.close_rounded, color: AppColors.muted),
              tooltip: 'Fermer le ticket',
              onPressed: _closeTicket,
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.muted, size: 20),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Erreur: $_error', style: const TextStyle(color: AppColors.muted)))
              : Column(
                  children: [
                    // ── Messages ───────────────────────────────────────────
                    Expanded(
                      child: ticket!.messages.isEmpty
                          ? const Center(
                              child: Text('Aucun message',
                                  style: TextStyle(color: AppColors.muted, fontSize: 13)),
                            )
                          : ListView.builder(
                              controller: _scrollCtrl,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              itemCount: ticket.messages.length,
                              itemBuilder: (ctx, i) => _buildBubble(ticket.messages[i], palette),
                            ),
                    ),

                    // ── Ticket fermé ───────────────────────────────────────
                    if (ticket.isClosed)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        color: const Color(0xFF1A1A1A),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.lock_rounded, color: AppColors.muted, size: 14),
                            SizedBox(width: 6),
                            Text('Ce ticket est fermé',
                                style: TextStyle(color: AppColors.muted, fontSize: 13)),
                          ],
                        ),
                      ),

                    // ── Champ de réponse ───────────────────────────────────
                    if (!ticket.isClosed)
                      Container(
                        padding: EdgeInsets.fromLTRB(
                          12, 10, 12, MediaQuery.of(context).viewInsets.bottom + 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111111),
                          border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.2))),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _msgCtrl,
                                style: const TextStyle(color: AppColors.text, fontSize: 13.5),
                                maxLines: 4,
                                minLines: 1,
                                textInputAction: TextInputAction.newline,
                                decoration: InputDecoration(
                                  hintText: 'Votre message…',
                                  hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
                                  filled: true,
                                  fillColor: const Color(0xFF1C1C1C),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(22),
                                    borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.25)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(22),
                                    borderSide: BorderSide(color: palette.accent.withValues(alpha: 0.5)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _sending ? null : _send,
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: _sending ? const Color(0xFF333333) : palette.accentStrong,
                                  shape: BoxShape.circle,
                                ),
                                child: _sending
                                    ? const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _buildBubble(_Message msg, MbongoThemePalette palette) {
    final isUser = msg.isUser;
    final time = DateFormat('HH:mm').format(msg.createdAt.toLocal());

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.support_agent_rounded, color: AppColors.muted, size: 16),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? palette.accentStrong.withValues(alpha: 0.85)
                        : const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: AppColors.border.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    msg.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : AppColors.text,
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                  child: Text(time,
                      style: const TextStyle(color: AppColors.muted, fontSize: 10.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
        'OPEN' => const Color(0xFF4CAF50),
        'IN_PROGRESS' => const Color(0xFFC9A84C),
        _ => AppColors.muted,
      };

  String _statusLabel(String status) => switch (status) {
        'OPEN' => 'Ouvert',
        'IN_PROGRESS' => 'En cours',
        _ => 'Fermé',
      };
}
