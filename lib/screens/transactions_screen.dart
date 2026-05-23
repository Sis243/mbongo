import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/mbongo_theme.dart';
import '../features/wallet/presentation/wallet_notifier.dart';
import '../widgets/common/mbongo_money_particles.dart';
import '../widgets/common/mbongo_sub_app_bar.dart';
import '../widgets/txn_tile.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  int selectedPeriod = 0;
  String selectedCategory = 'Toutes';
  String selectedStatus = 'Tous';
  String searchQuery = '';

  final TextEditingController searchCtrl = TextEditingController();

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  String _formatLedgerValue(dynamic value) {
    final amount = _toDouble(value);
    return amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ',
    );
  }

  void _showTransactionDetails(Map<String, dynamic> tx) {
    final palette = MbongoThemeController.current;
    final rawDate = tx['date'];
    final date = rawDate is DateTime
        ? rawDate
        : DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
    final description = (tx['description'] ?? tx['motif'] ?? '').toString();
    final metadata = (tx['metadata'] ?? '').toString();
    final balanceBefore = tx['balanceBefore'];
    final balanceAfter = tx['balanceAfter'];
    final entryType = (tx['entryType'] ?? tx['type'] ?? '').toString();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: palette.panelAlt,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.24),
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Detail du mouvement',
                    style: TextStyle(
                      color: AppColors.darkText,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _detailRow('Libelle', (tx['label'] ?? '').toString()),
                  _detailRow('Type comptable', entryType),
                  _detailRow('Date', _formatDate(date)),
                  _detailRow(
                    'Montant',
                    '${_currencyOf(tx)} ${_formatLedgerValue(tx['amount'])}',
                  ),
                  _detailRow('Sens', (tx['isCredit'] ?? false) == true ? 'Credit' : 'Debit'),
                  if (balanceBefore != null)
                    _detailRow(
                      'Solde avant',
                      '${_currencyOf(tx)} ${_formatLedgerValue(balanceBefore)}',
                    ),
                  if (balanceAfter != null)
                    _detailRow(
                      'Solde apres',
                      '${_currencyOf(tx)} ${_formatLedgerValue(balanceAfter)}',
                    ),
                  if (description.trim().isNotEmpty)
                    _detailRow('Description', description),
                  if (metadata.trim().isNotEmpty)
                    _detailRow('Metadata', metadata),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Fermer'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.darkMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(
              color: AppColors.darkText,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _filterTransactions(List<Map<String, dynamic>> txs) {
    final now = DateTime.now();

    return txs.where((tx) {
      final rawDate = tx['date'];
      final date = rawDate is DateTime
          ? rawDate
          : DateTime.tryParse(rawDate.toString()) ?? DateTime.now();

      bool matchPeriod = true;

      if (selectedPeriod == 0) {
        matchPeriod =
            date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      } else if (selectedPeriod == 1) {
        matchPeriod = now.difference(date).inDays <= 7;
      } else if (selectedPeriod == 2) {
        matchPeriod = now.difference(date).inDays <= 30;
      }

      final label = (tx['label'] ?? '').toString().toLowerCase();
      final type = (tx['type'] ?? '').toString().toUpperCase();
      final status = (tx['status'] ?? '').toString().toUpperCase();

      final matchSearch = searchQuery.trim().isEmpty
          ? true
          : label.contains(searchQuery.toLowerCase()) ||
              type.contains(searchQuery.toUpperCase());

      final category = _resolveCategory(type);
      final matchCategory =
          selectedCategory == 'Toutes' ? true : category == selectedCategory;

      final matchStatus = selectedStatus == 'Tous'
          ? true
          : selectedStatus == 'Succes'
              ? status == 'SUCCESS'
              : selectedStatus == 'En attente'
                  ? status == 'PENDING'
                  : status == 'FAILED';

      return matchPeriod && matchSearch && matchCategory && matchStatus;
    }).toList();
  }

  String _resolveCategory(String type) {
    switch (type) {
      case 'TRANSFERT':
        return 'Transferts';
      case 'DEMANDE_ARGENT':
        return 'Demandes';
      case 'RETRAIT':
        return 'Retraits';
      case 'DEPOT':
      case 'RECEPTION':
        return 'Depots';
      case 'AIRTIME':
        return 'Unites';
      case 'TV':
        return 'TV';
      case 'EXCHANGE':
        return 'Echanges';
      case 'CARTE':
      case 'CARTE_RECHARGE':
        return 'Cartes';
      case 'QR_PAY':
      case 'PAIEMENT':
        return 'Paiements';
      default:
        return 'Autres';
    }
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  String _currencyOf(Map<String, dynamic> tx) {
    return (tx['currency'] ?? 'CDF').toString().toUpperCase();
  }

  Map<String, double> _stats(List<Map<String, dynamic>> txs) {
    double credits = 0;
    double debits = 0;

    for (final tx in txs) {
      final amount = _toDouble(tx['amount']);
      final isCredit = (tx['isCredit'] ?? false) == true;
      if (isCredit) {
        credits += amount;
      } else {
        debits += amount;
      }
    }

    return {
      'credits': credits,
      'debits': debits,
      'count': txs.length.toDouble(),
      'net': credits - debits,
    };
  }

  Map<String, double> _categoryTotals(List<Map<String, dynamic>> txs) {
    final Map<String, double> totals = {};

    for (final tx in txs) {
      final type = (tx['type'] ?? '').toString().toUpperCase();
      final category = _resolveCategory(type);
      final amount = _toDouble(tx['amount']);
      final isCredit = (tx['isCredit'] ?? false) == true;

      if (!isCredit) {
        totals[category] = (totals[category] ?? 0) + amount;
      }
    }

    if (totals.isEmpty) {
      totals['Aucune depense'] = 0;
    }

    return totals;
  }

  Future<void> _exportPdf(List<Map<String, dynamic>> txs) async {
    final pdf = pw.Document();
    final stats = _stats(txs);

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(24),
        ),
        build: (context) => [
          pw.Text(
            'MBONGO - Historique des transactions',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Periode: ${_periodLabel(selectedPeriod)} | Categorie: $selectedCategory',
            style: const pw.TextStyle(
              fontSize: 11,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Row(
            children: [
              _pdfStatCard('Entrees', stats['credits'] ?? 0),
              pw.SizedBox(width: 10),
              _pdfStatCard('Sorties', stats['debits'] ?? 0),
              pw.SizedBox(width: 10),
              _pdfStatCard('Solde net', stats['net'] ?? 0),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blue700,
            ),
            cellStyle: const pw.TextStyle(fontSize: 10),
            headers: const ['Date', 'Libelle', 'Type', 'Montant', 'Devise'],
            data: txs.map((tx) {
              final date = DateTime.tryParse((tx['date'] ?? '').toString()) ??
                  DateTime.now();

              return [
                '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                (tx['label'] ?? '').toString(),
                (tx['type'] ?? '').toString(),
                _toDouble(tx['amount']).toStringAsFixed(2),
                _currencyOf(tx),
              ];
            }).toList(),
          ),
        ],
      ),
    );

    final bytes = await pdf.save();

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'mbongo_transactions.pdf',
    );
  }

  pw.Widget _pdfStatCard(String title, double value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.grey400),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value.toStringAsFixed(2),
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _periodLabel(int value) {
    switch (value) {
      case 0:
        return "Aujourd'hui";
      case 1:
        return '7 jours';
      case 2:
        return '30 jours';
      default:
        return 'Tout';
    }
  }

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    final hh = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min';
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    final walletData = ref.watch(walletProvider).valueOrNull;
    final allTxs = walletData?.transactions.map((t) => t.toMap()).toList() ?? [];
    final filtered = _filterTransactions(allTxs);
    final stats = _stats(filtered);
    final categoryTotals = _categoryTotals(filtered);

    return Scaffold(
      backgroundColor: palette.shellBottom,
      appBar: MbongoSubAppBar(
        title: 'Mouvements',
        actions: [
          IconButton(
            tooltip: 'Exporter PDF',
            onPressed: filtered.isEmpty ? null : () => _exportPdf(filtered),
            icon: const Icon(Icons.picture_as_pdf_rounded),
          ),
        ],
      ),
      body: DecoratedBox(
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
                  count: 21,
                  opacity: 0.11,
                ),
              ),
            ),
            RefreshIndicator(
              onRefresh: () => ref.read(walletProvider.notifier).refresh(),
              child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                _buildSearchBar(),
                const SizedBox(height: 14),
                _buildPeriodFilter(),
                const SizedBox(height: 14),
                _buildCategoryFilter(),
                const SizedBox(height: 10),
                _buildStatusFilter(),
                const SizedBox(height: 16),
                _buildStatsCards(stats),
                const SizedBox(height: 18),
                _buildChartCard(categoryTotals),
                const SizedBox(height: 18),
                const Text(
                  'Transactions',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: palette.panelAlt,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.24),
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 42,
                          color: AppColors.darkMuted,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Aucune transaction trouvee pour cette periode.',
                          style: TextStyle(
                            color: AppColors.darkText,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...filtered.map(
                    (tx) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () => _showTransactionDetails(tx),
                        child: TxnTile(txn: tx),
                      ),
                    ),
                  ),
              ],
            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: searchCtrl,
      onChanged: (value) {
        setState(() => searchQuery = value);
      },
      style: const TextStyle(
        color: AppColors.darkText,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: MbongoThemeController.current.panelAlt,
        hintText: 'Rechercher une transaction...',
        hintStyle: const TextStyle(color: AppColors.darkMuted),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: MbongoThemeController.current.accent,
        ),
        suffixIcon: searchQuery.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  searchCtrl.clear();
                  setState(() => searchQuery = '');
                },
                icon: const Icon(Icons.close_rounded),
              ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: AppColors.border.withValues(alpha: 0.24),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: MbongoThemeController.current.accent,
            width: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodFilter() {
    final palette = MbongoThemeController.current;
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 0, label: Text("Aujourd'hui")),
        ButtonSegment(value: 1, label: Text('7 jours')),
        ButtonSegment(value: 2, label: Text('30 jours')),
        ButtonSegment(value: 3, label: Text('Tout')),
      ],
      selected: {selectedPeriod},
      onSelectionChanged: (value) {
        setState(() => selectedPeriod = value.first);
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return palette.accentStrong;
          }
          return palette.panel;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return Colors.white;
        }),
        side: WidgetStateProperty.all(
          BorderSide(color: palette.accent.withValues(alpha: 0.28)),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final palette = MbongoThemeController.current;
    const categories = [
      'Toutes',
      'Transferts',
      'Demandes',
      'Retraits',
      'Depots',
      'Paiements',
      'Unites',
      'TV',
      'Echanges',
      'Cartes',
      'Autres',
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final item = categories[i];
          final selected = item == selectedCategory;

          return GestureDetector(
            onTap: () => setState(() => selectedCategory = item),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? palette.accent : palette.panelAlt,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected
                      ? palette.accent
                      : AppColors.border.withValues(alpha: 0.28),
                ),
              ),
              child: Text(
                item,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.darkText,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusFilter() {
    final palette = MbongoThemeController.current;
    const statuses = ['Tous', 'Succes', 'En attente', 'Echec'];

    return Row(
      children: statuses.map((s) {
        final selected = s == selectedStatus;
        Color color;
        if (s == 'Succes') {
          color = AppColors.green;
        } else if (s == 'En attente') {
          color = AppColors.gold;
        } else if (s == 'Echec') {
          color = AppColors.red;
        } else {
          color = palette.accent;
        }

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => setState(() => selectedStatus = s),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? color.withValues(alpha: 0.18) : palette.panelAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? color : AppColors.border.withValues(alpha: 0.24),
                    width: selected ? 1.4 : 1,
                  ),
                ),
                child: Text(
                  s,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? color : AppColors.darkMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatsCards(Map<String, double> stats) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            title: 'Entrees',
            value: stats['credits'] ?? 0,
            color: AppColors.green,
            icon: Icons.south_west_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            title: 'Sorties',
            value: stats['debits'] ?? 0,
            color: AppColors.red,
            icon: Icons.north_east_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            title: 'Solde net',
            value: stats['net'] ?? 0,
            color: MbongoThemeController.current.accent,
            icon: Icons.account_balance_wallet_rounded,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required double value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MbongoThemeController.current.panelAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.24),
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.darkMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.toStringAsFixed(0),
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(Map<String, double> categoryTotals) {
    final entries = categoryTotals.entries.toList();
    final total = entries.fold<double>(0, (sum, e) => sum + e.value);

    final colors = [
      MbongoThemeController.current.accent,
      MbongoThemeController.current.accentStrong,
      AppColors.red,
      AppColors.green,
      AppColors.cyan,
      AppColors.orange,
      AppColors.blueDark,
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MbongoThemeController.current.panelAlt,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.24),
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Repartition des depenses',
            style: TextStyle(
              color: AppColors.darkText,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Repartition des sorties par categorie',
            style: TextStyle(
              color: AppColors.darkMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 220,
            child: total <= 0
                ? const Center(
                    child: Text(
                      'Aucune depense a afficher.',
                      style: TextStyle(
                        color: AppColors.darkMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : PieChart(
                    PieChartData(
                      centerSpaceRadius: 46,
                      sectionsSpace: 3,
                      sections: List.generate(entries.length, (index) {
                        final item = entries[index];
                        final color = colors[index % colors.length];
                        final percent = total == 0 ? 0 : (item.value / total) * 100;

                        return PieChartSectionData(
                          value: item.value,
                          radius: 56,
                          color: color,
                          title: '${percent.toStringAsFixed(0)}%',
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        );
                      }),
                    ),
                  ),
          ),
          const SizedBox(height: 18),
          ...List.generate(entries.length, (index) {
            final item = entries[index];
            final color = colors[index % colors.length];

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.key,
                      style: const TextStyle(
                        color: AppColors.darkText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    item.value.toStringAsFixed(0),
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
