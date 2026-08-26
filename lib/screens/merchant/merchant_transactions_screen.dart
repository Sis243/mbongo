import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api/dio_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../widgets/common/mbongo_sub_app_bar.dart';

final _merchantTxnsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.read(dioClientProvider);
  try {
    final resp = await client.get('/merchant/my-receipts');
    final list = resp['data'];
    if (list is List) {
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  } catch (_) {
    return [];
  }
});

class MerchantTransactionsScreen extends ConsumerStatefulWidget {
  const MerchantTransactionsScreen({super.key});

  @override
  ConsumerState<MerchantTransactionsScreen> createState() =>
      _MerchantTransactionsScreenState();
}

class _MerchantTransactionsScreenState
    extends ConsumerState<MerchantTransactionsScreen> {
  String _period = 'Mois';
  String _status = 'Tous';

  static const _periods = ['Aujourd\'hui', 'Semaine', 'Mois', 'Tout'];
  static const _statuses = ['Tous', 'Succès', 'En attente', 'Échoué'];

  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> list) {
    final now = DateTime.now();
    return list.where((tx) {
      final raw = tx['date'] ?? tx['createdAt'];
      final date = raw != null
          ? (raw is DateTime ? raw : DateTime.tryParse(raw.toString()) ?? now)
          : now;

      bool matchPeriod = true;
      if (_period == 'Aujourd\'hui') {
        matchPeriod =
            date.year == now.year && date.month == now.month && date.day == now.day;
      } else if (_period == 'Semaine') {
        matchPeriod = now.difference(date).inDays <= 7;
      } else if (_period == 'Mois') {
        matchPeriod = now.difference(date).inDays <= 30;
      }

      final s = (tx['status'] ?? '').toString().toUpperCase();
      bool matchStatus = true;
      if (_status == 'Succès') { matchStatus = s == 'SUCCESS'; }
      else if (_status == 'En attente') { matchStatus = s == 'PENDING'; }
      else if (_status == 'Échoué') { matchStatus = s == 'FAILED'; }

      return matchPeriod && matchStatus;
    }).toList();
  }

  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case 'SUCCESS': return AppColors.green;
      case 'FAILED': return AppColors.red;
      case 'PENDING': return AppColors.gold;
      default: return AppColors.textSoft;
    }
  }

  String _statusLabel(String s) {
    switch (s.toUpperCase()) {
      case 'SUCCESS': return 'Succès';
      case 'FAILED': return 'Échoué';
      case 'PENDING': return 'En attente';
      default: return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    final dataAsync = ref.watch(_merchantTxnsProvider);
    final fmt = NumberFormat('#,##0', 'fr_FR');

    return Scaffold(
      backgroundColor: palette.shellBottom,
      appBar: MbongoSubAppBar(title: 'Transactions'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.shellTop, palette.shellBottom],
          ),
        ),
        child: Column(
          children: [
            // Filters
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FilterRow(
                    label: 'Période',
                    options: _periods,
                    selected: _period,
                    onSelect: (v) => setState(() => _period = v),
                    color: AppColors.green,
                  ),
                  const SizedBox(height: 8),
                  _FilterRow(
                    label: 'Statut',
                    options: _statuses,
                    selected: _status,
                    onSelect: (v) => setState(() => _status = v),
                    color: AppColors.cyan,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // List
            Expanded(
              child: dataAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green),
                ),
                error: (_, __) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded, color: AppColors.textSoft, size: 44),
                      const SizedBox(height: 12),
                      const Text('Impossible de charger',
                          style: TextStyle(color: AppColors.textSoft, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: () => ref.refresh(_merchantTxnsProvider),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
                data: (list) {
                  final filtered = _filter(list);

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_rounded,
                              size: 52, color: AppColors.green.withValues(alpha: 0.4)),
                          const SizedBox(height: 14),
                          const Text('Aucune transaction',
                              style: TextStyle(
                                  color: AppColors.text,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          const Text('Aucun résultat pour ce filtre.',
                              style: TextStyle(color: AppColors.textSoft, fontSize: 13)),
                        ],
                      ),
                    );
                  }

                  // Summary row
                  final total = filtered
                      .where((t) => (t['status'] ?? '').toString().toUpperCase() == 'SUCCESS')
                      .fold(0.0, (s, t) => s + ((t['amount'] as num?)?.toDouble() ?? 0));

                  return RefreshIndicator(
                    color: AppColors.green,
                    onRefresh: () => ref.refresh(_merchantTxnsProvider.future),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      children: [
                        // Summary chip
                        Container(
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.green.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.green.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '${filtered.length} transactions',
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${fmt.format(total)} CDF encaissés',
                                style: const TextStyle(
                                  color: AppColors.green,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),

                        ...filtered.map((tx) {
                          final type = (tx['type'] ?? '').toString();
                          final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
                          final currency = tx['currency']?.toString() ?? 'CDF';
                          final status = (tx['status'] ?? '').toString();
                          final isCredit = tx['isCredit'] == true ||
                              type == 'depot' || type == 'reception' || type == 'demande_argent';
                          final raw = tx['date'] ?? tx['createdAt'];
                          final date = raw != null
                              ? DateFormat('dd/MM/yy  HH:mm', 'fr_FR').format(
                                  (raw is DateTime ? raw : DateTime.parse(raw.toString())).toLocal())
                              : '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: palette.panelAlt,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: AppColors.border.withValues(alpha: 0.18)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: (isCredit ? AppColors.green : AppColors.orange)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: Icon(
                                    isCredit
                                        ? Icons.arrow_downward_rounded
                                        : Icons.arrow_upward_rounded,
                                    color: isCredit ? AppColors.green : AppColors.orange,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        type.replaceAll('-', ' ').replaceAll('_', ' ').toUpperCase(),
                                        style: const TextStyle(
                                          color: AppColors.text,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        date,
                                        style: const TextStyle(
                                          color: AppColors.textSoft,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${isCredit ? '+' : '-'}${fmt.format(amount)} $currency',
                                      style: TextStyle(
                                        color: isCredit ? AppColors.green : AppColors.text,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _statusColor(status).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        _statusLabel(status),
                                        style: TextStyle(
                                          color: _statusColor(status),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
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
}

class _FilterRow extends StatelessWidget {
  final String label;
  final List<String> options;
  final String selected;
  final void Function(String) onSelect;
  final Color color;

  const _FilterRow({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelect,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 58,
          child: Text(label,
              style: const TextStyle(
                  color: AppColors.textSoft,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: options.map((opt) {
                final sel = opt == selected;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => onSelect(opt),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel ? color.withValues(alpha: 0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: sel ? color.withValues(alpha: 0.5) : AppColors.border.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        opt,
                        style: TextStyle(
                          color: sel ? color : AppColors.textSoft,
                          fontSize: 12,
                          fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
