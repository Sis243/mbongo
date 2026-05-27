import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api/dio_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../widgets/common/mbongo_sub_app_bar.dart';

final _agentPayoutsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final client = ref.read(dioClientProvider);
  try {
    final resp = await client.get('/transactions/agent/profit-log');
    return Map<String, dynamic>.from(resp as Map);
  } catch (_) {
    return {};
  }
});

class AgentPayoutsScreen extends ConsumerWidget {
  const AgentPayoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = MbongoThemeController.current;
    final dataAsync = ref.watch(_agentPayoutsProvider);

    return Scaffold(
      backgroundColor: palette.shellBottom,
      appBar: MbongoSubAppBar(title: 'Commissions & Versements'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.shellTop, palette.shellBottom],
          ),
        ),
        child: dataAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.orange,
            ),
          ),
          error: (_, __) => _buildError(ref),
          data: (data) => _buildContent(context, ref, data, palette),
        ),
      ),
    );
  }

  Widget _buildError(WidgetRef ref) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: AppColors.textSoft, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Impossible de charger les données.',
              style: TextStyle(color: AppColors.textSoft, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () => ref.refresh(_agentPayoutsProvider),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> data,
    MbongoThemePalette palette,
  ) {
    final fmt = NumberFormat('#,##0', 'fr_FR');
    final balance = (data['commissionBalance'] as num?)?.toDouble() ?? 0;
    final agentName = data['agentName']?.toString() ?? '';
    final agentCode = data['agentCode']?.toString() ?? '';
    final txns = (data['transactions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final payouts = (data['payouts'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return RefreshIndicator(
      color: AppColors.orange,
      onRefresh: () => ref.refresh(_agentPayoutsProvider.future),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Balance card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A0A00), Color(0xFF3D1A00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.orange.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_rounded, color: AppColors.orange, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Solde de commissions',
                      style: TextStyle(color: AppColors.textSoft, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    if (agentCode.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(agentCode,
                            style: const TextStyle(color: AppColors.orange, fontSize: 11, fontWeight: FontWeight.w800)),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${fmt.format(balance)} CDF',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                if (agentName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(agentName, style: const TextStyle(color: AppColors.textSoft, fontSize: 12)),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    _statChip('${txns.length}', 'Opérations', AppColors.green),
                    const SizedBox(width: 10),
                    _statChip('${payouts.length}', 'Versements', AppColors.cyan),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Versements reçus
          if (payouts.isNotEmpty) ...[
            _sectionTitle('Versements reçus', AppColors.cyan, Icons.payments_rounded),
            const SizedBox(height: 10),
            ...payouts.map((p) => _payoutTile(p, palette, fmt)),
            const SizedBox(height: 20),
          ],

          // Commissions récentes
          if (txns.isNotEmpty) ...[
            _sectionTitle('Commissions sur transactions', AppColors.green, Icons.bar_chart_rounded),
            const SizedBox(height: 10),
            ...txns.map((t) => _commissionTile(t, palette, fmt)),
          ],

          if (payouts.isEmpty && txns.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.payments_rounded, size: 48, color: AppColors.orange),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucune commission pour l\'instant',
                    style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Vos commissions apparaîtront ici après chaque transaction traitée.',
                    style: TextStyle(color: AppColors.textSoft, fontSize: 13, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _statChip(String value, String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900)),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
      );

  Widget _sectionTitle(String title, Color color, IconData icon) => Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800)),
        ],
      );

  Widget _payoutTile(Map<String, dynamic> p, MbongoThemePalette palette, NumberFormat fmt) {
    final amount = (p['amount'] as num?)?.toDouble() ?? 0;
    final note = p['note']?.toString() ?? '';
    final ref = p['reference']?.toString() ?? '';
    final date = p['createdAt'] != null
        ? DateFormat('dd MMM yyyy', 'fr_FR').format(
            DateTime.parse(p['createdAt'].toString()).toLocal())
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.payments_rounded, color: AppColors.cyan, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Versement reçu',
                    style: TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w800)),
                Text(
                  [if (note.isNotEmpty) note, if (ref.isNotEmpty) 'Réf: $ref', if (date.isNotEmpty) date]
                      .join(' · '),
                  style: const TextStyle(color: AppColors.textSoft, fontSize: 11.5),
                ),
              ],
            ),
          ),
          Text(
            '+${fmt.format(amount)} CDF',
            style: const TextStyle(color: AppColors.cyan, fontSize: 14, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _commissionTile(Map<String, dynamic> t, MbongoThemePalette palette, NumberFormat fmt) {
    final commission = (t['commission'] as num?)?.toDouble() ?? 0;
    final amount = (t['amount'] as num?)?.toDouble() ?? 0;
    final type = t['type']?.toString() ?? '';
    final currency = t['currency']?.toString() ?? 'CDF';
    final isCashOut = type.contains('cashout') || type.contains('withdrawal');
    final date = t['createdAt'] != null
        ? DateFormat('dd MMM yyyy', 'fr_FR').format(
            DateTime.parse(t['createdAt'].toString()).toLocal())
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isCashOut ? AppColors.orange : AppColors.green).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCashOut ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: isCashOut ? AppColors.orange : AppColors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.replaceAll('-', ' ').toUpperCase(),
                  style: const TextStyle(color: AppColors.text, fontSize: 12, fontWeight: FontWeight.w800),
                ),
                Text(
                  '${fmt.format(amount)} $currency · $date',
                  style: const TextStyle(color: AppColors.textSoft, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${fmt.format(commission)} $currency',
                style: const TextStyle(color: AppColors.green, fontSize: 13, fontWeight: FontWeight.w900),
              ),
              const Text('commission', style: TextStyle(color: AppColors.textSoft, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
