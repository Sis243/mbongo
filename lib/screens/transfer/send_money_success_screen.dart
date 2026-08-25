import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../widgets/common/mbongo_money_particles.dart';
import '../../widgets/common/mbongo_sub_app_bar.dart';

class SendMoneySuccessScreen extends StatefulWidget {
  final String phone;
  final String name;
  final double amount;
  final String currency;
  final String reason;

  const SendMoneySuccessScreen({
    super.key,
    required this.phone,
    required this.name,
    required this.amount,
    required this.currency,
    required this.reason,
  });

  @override
  State<SendMoneySuccessScreen> createState() => _SendMoneySuccessScreenState();
}

class _SendMoneySuccessScreenState extends State<SendMoneySuccessScreen> {
  final _receiptKey = GlobalKey();
  bool _sharing = false;

  String _formatAmount(double value) =>
      value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);

  String get _displayName =>
      widget.name.isNotEmpty ? widget.name : widget.phone;

  Future<void> _shareImage() async {
    setState(() => _sharing = true);
    try {
      final boundary =
          _receiptKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        _shareText();
        return;
      }
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        _shareText();
        return;
      }
      final tmp = await getTemporaryDirectory();
      final file = File('${tmp.path}/recu_mbongo.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        subject: 'Reçu MBONGO — ${widget.currency} ${_formatAmount(widget.amount)}',
      );
    } catch (_) {
      _shareText();
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  void _shareText() {
    Share.share(
      'MBONGO — Transfert réussi\n'
      'Montant : ${widget.currency} ${_formatAmount(widget.amount)}\n'
      'Bénéficiaire : $_displayName\n'
      'Téléphone : ${widget.phone}\n'
      'Motif : ${widget.reason.isEmpty ? "-" : widget.reason}\n'
      '---\nOpération sécurisée via MBONGO.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;

    return Scaffold(
      backgroundColor: palette.shellBottom,
      appBar: MbongoSubAppBar(title: 'Confirmation'),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [palette.shellTop, palette.shellBottom],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: MbongoMoneyParticles(
                color: palette.accent,
                count: 20,
                opacity: 0.11,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  // ── Reçu captureable ────────────────────────────────────
                  RepaintBoundary(
                    key: _receiptKey,
                    child: _ReceiptCard(
                      palette: palette,
                      name: _displayName,
                      phone: widget.phone,
                      amount: widget.amount,
                      currency: widget.currency,
                      reason: widget.reason,
                      formatAmount: _formatAmount,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Bandeau sécurité ─────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: palette.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: palette.accent.withValues(alpha: 0.24)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.security, color: palette.accentStrong, size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Opération traitée dans un environnement sécurisé.',
                            style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // ── Boutons ──────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _sharing ? null : _shareImage,
                      icon: _sharing
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.share_rounded),
                      label: Text(_sharing ? 'Préparation...' : 'Partager le reçu'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.popUntil(context, (route) => route.isFirst),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.accentStrong,
                      ),
                      child: const Text('Terminer'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widget reçu (captureable en PNG) ────────────────────────────────────────

class _ReceiptCard extends StatelessWidget {
  final MbongoThemePalette palette;
  final String name;
  final String phone;
  final double amount;
  final String currency;
  final String reason;
  final String Function(double) formatAmount;

  const _ReceiptCard({
    required this.palette,
    required this.name,
    required this.phone,
    required this.amount,
    required this.currency,
    required this.reason,
    required this.formatAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: palette.glow.withValues(alpha: 0.15),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-tête gradient avec icône succès
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: palette.bannerGradient,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.12),
                    border: Border.all(color: AppColors.gold, width: 2),
                  ),
                  child: const Icon(Icons.check_rounded, color: AppColors.gold, size: 40),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Transaction réussie',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '$currency ${formatAmount(amount)}',
                  style: const TextStyle(color: AppColors.gold, fontSize: 26, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),

          // Détails
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _row('Bénéficiaire', name),
                const _Sep(),
                _row('Téléphone', phone),
                const _Sep(),
                _row('Motif', reason.isEmpty ? '-' : reason),
                const _Sep(),
                _row('Statut', 'Validé ✓', valueColor: AppColors.green),
                const SizedBox(height: 16),
                // Footer MBONGO
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_rounded, color: palette.accent, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      'Sécurisé par MBONGO · CADECO',
                      style: TextStyle(color: palette.accent, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(color: valueColor ?? AppColors.text, fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _Sep extends StatelessWidget {
  const _Sep();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 20, color: Color(0x22FFFFFF));
}
