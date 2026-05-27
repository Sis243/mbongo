import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/mbongo_theme.dart';
import '../features/wallet/domain/wallet_state.dart';
import '../widgets/common/mbongo_sub_app_bar.dart';
import 'dispute/dispute_screen.dart';

class TransactionDetailScreen extends StatelessWidget {
  final TxEntry tx;

  const TransactionDetailScreen({super.key, required this.tx});

  List<_TStep> get _timeline {
    final s = tx.status.toUpperCase();
    return [
      _TStep(label: 'Initié', sub: _fmtDate(tx.date), done: true, color: AppColors.cyan),
      _TStep(
        label: 'En traitement',
        sub: s == 'PENDING' ? 'En cours...' : null,
        done: s != 'PENDING',
        color: s == 'PENDING' ? AppColors.gold : AppColors.cyan,
        active: s == 'PENDING',
      ),
      _TStep(
        label: s == 'FAILED' ? 'Échoué' : s == 'REVERSED' ? 'Remboursé' : 'Confirmé',
        sub: s == 'SUCCESS'
            ? 'Transaction réussie'
            : s == 'FAILED'
                ? 'Transaction échouée'
                : s == 'REVERSED'
                    ? 'Transaction remboursée'
                    : null,
        done: s == 'SUCCESS' || s == 'REVERSED' || s == 'FAILED',
        color: s == 'FAILED' ? AppColors.red : s == 'REVERSED' ? AppColors.gold : AppColors.green,
        active: s == 'SUCCESS' || s == 'FAILED' || s == 'REVERSED',
      ),
    ];
  }

  String _fmtDate(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}  $h:$m';
  }

  String _fmtAmt(double a) => a
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

  Color _statusColor(String s) {
    switch (s) {
      case 'SUCCESS': return AppColors.green;
      case 'FAILED': return AppColors.red;
      case 'REVERSED': return AppColors.gold;
      case 'PENDING': return AppColors.gold;
      default: return AppColors.textSoft;
    }
  }

  String _typeLabel(String t) {
    switch (t.toLowerCase()) {
      case 'transfer': return 'Virement';
      case 'depot': case 'deposit': return 'Dépôt';
      case 'reception': return 'Réception';
      case 'withdrawal': case 'retrait': return 'Retrait';
      case 'cashin': return 'Cash-In';
      case 'cashout': return 'Cash-Out';
      case 'airtime': return 'Recharge mobile';
      case 'tv': return 'Abonnement TV';
      case 'exchange': return 'Change de devises';
      case 'merchant_pay': return 'Paiement marchand';
      default: return t.replaceAll('_', ' ').toUpperCase();
    }
  }

  IconData _typeIcon(String t) {
    switch (t.toLowerCase()) {
      case 'transfer': return Icons.swap_horiz_rounded;
      case 'depot': case 'deposit': return Icons.add_circle_outline_rounded;
      case 'reception': return Icons.call_received_rounded;
      case 'withdrawal': case 'retrait': return Icons.arrow_upward_rounded;
      case 'cashin': return Icons.arrow_downward_rounded;
      case 'cashout': return Icons.arrow_upward_rounded;
      case 'airtime': return Icons.phone_android_rounded;
      case 'tv': return Icons.tv_rounded;
      case 'exchange': return Icons.currency_exchange_rounded;
      default: return Icons.receipt_long_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    final status = tx.status.toUpperCase();
    final iconColor = tx.isCredit ? AppColors.green : AppColors.orange;

    return Scaffold(
      backgroundColor: palette.shellBottom,
      appBar: MbongoSubAppBar(title: 'Détail de la transaction'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.shellTop, palette.shellBottom],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // Amount hero
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: palette.panel,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _statusColor(status).withValues(alpha: 0.25)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(_typeIcon(tx.type), color: iconColor, size: 28),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${tx.isCredit ? '+' : '-'}${_fmtAmt(tx.amount)} ${tx.currency}',
                    style: TextStyle(
                      color: tx.isCredit ? AppColors.green : AppColors.text,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _typeLabel(tx.type),
                    style: const TextStyle(
                      color: AppColors.textSoft,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _statusColor(status).withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: _statusColor(status),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Timeline
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: palette.panelAlt,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.22)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Progression',
                    style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  ..._timeline.asMap().entries.map((e) {
                    final i = e.key;
                    final step = e.value;
                    final isLast = i == _timeline.length - 1;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: step.done
                                    ? step.color.withValues(alpha: 0.16)
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: step.done
                                      ? step.color
                                      : AppColors.border.withValues(alpha: 0.4),
                                  width: step.active ? 2 : 1,
                                ),
                              ),
                              child: step.done
                                  ? Icon(
                                      step.active && status == 'FAILED'
                                          ? Icons.close_rounded
                                          : Icons.check_rounded,
                                      color: step.color,
                                      size: 13,
                                    )
                                  : null,
                            ),
                            if (!isLast)
                              Container(
                                width: 2,
                                height: 30,
                                color: step.done
                                    ? step.color.withValues(alpha: 0.25)
                                    : AppColors.border.withValues(alpha: 0.2),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: 2, bottom: isLast ? 0 : 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step.label,
                                  style: TextStyle(
                                    color: step.done ? AppColors.text : AppColors.textSoft,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                if (step.sub != null)
                                  Text(
                                    step.sub!,
                                    style: TextStyle(
                                      color: step.active ? step.color : AppColors.textSoft,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Info details
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: palette.panelAlt,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.22)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informations',
                    style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  _row('Date', _fmtDate(tx.date)),
                  _row('Type', _typeLabel(tx.type)),
                  if (tx.target.isNotEmpty)
                    _row(tx.isCredit ? 'Expéditeur' : 'Bénéficiaire', tx.target),
                  if (tx.motif.isNotEmpty) _row('Motif', tx.motif),
                  _row('Devise', tx.currency),
                  _copyRow('Référence', tx.id, context),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Signaler un problème
            if (status != 'PENDING')
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DisputeScreen(prefilledTransactionId: tx.id),
                  ),
                ),
                icon: const Icon(Icons.flag_rounded, size: 17),
                label: const Text('Signaler un problème'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.red,
                  side: BorderSide(color: AppColors.red.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  minimumSize: const Size(double.infinity, 0),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 112,
              child: Text(label,
                  style: const TextStyle(
                    color: AppColors.textSoft,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  )),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  )),
            ),
          ],
        ),
      );

  Widget _copyRow(String label, String value, BuildContext ctx) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 112,
              child: Text(label,
                  style: const TextStyle(
                    color: AppColors.textSoft,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  )),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Référence copiée'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.copy_rounded, size: 13, color: AppColors.textSoft),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

class _TStep {
  final String label;
  final String? sub;
  final bool done;
  final Color color;
  final bool active;

  const _TStep({
    required this.label,
    this.sub,
    required this.done,
    required this.color,
    this.active = false,
  });
}
