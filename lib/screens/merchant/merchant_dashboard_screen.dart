import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/api/dio_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../core/utils/money.dart';
import '../../widgets/common/mbongo_money_particles.dart';

final _merchantAccountsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.read(dioClientProvider);
  final resp = await client.get('/merchant/accounts');
  final list = resp['data'] ?? resp;
  if (list is List) return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  return [];
});

final _merchantTxProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.read(dioClientProvider);
  try {
    final resp = await client.get('/transactions?type=merchant-pay&limit=10');
    final list = resp['data'] ?? resp;
    if (list is List) return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return [];
  } catch (_) {
    return [];
  }
});

class MerchantDashboardScreen extends ConsumerWidget {
  const MerchantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = MbongoThemeController.current;
    final accountsAsync = ref.watch(_merchantAccountsProvider);
    final txAsync = ref.watch(_merchantTxProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                MbongoMoneyParticles(color: palette.accent, count: 10, opacity: 0.07, height: 200),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 52, 20, 28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: palette.bannerGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.store_rounded, color: AppColors.cyan, size: 20),
                          SizedBox(width: 8),
                          Text('Interface Marchand',
                              style: TextStyle(color: AppColors.textSoft, fontSize: 13, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('Tableau de bord',
                          style: TextStyle(color: AppColors.text, fontSize: 26, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 16),
                      accountsAsync.when(
                        data: (accounts) => _StatsRow(accounts: accounts),
                        loading: () => const _LoadingRow(),
                        error: (_, __) => const _LoadingRow(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Quick actions
                _sectionTitle('Actions rapides'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.qr_code_rounded,
                        label: 'Recevoir',
                        color: AppColors.green,
                        onTap: () => _showReceiveSheet(context, accountsAsync.value ?? []),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.link_rounded,
                        label: 'Lien paiement',
                        color: AppColors.cyan,
                        onTap: () => Navigator.pushNamed(context, '/merchant/links'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.arrow_upward_rounded,
                        label: 'Retirer',
                        color: AppColors.orange,
                        onTap: () => Navigator.pushNamed(context, '/merchant/withdraw'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Accounts
                accountsAsync.when(
                  data: (accounts) => accounts.isEmpty
                      ? const SizedBox()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle('Mes comptes marchands'),
                            const SizedBox(height: 10),
                            ...accounts.map((a) => _AccountCard(account: a)),
                          ],
                        ),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
                const SizedBox(height: 20),
                // Recent transactions
                _sectionTitle('Transactions récentes'),
                const SizedBox(height: 10),
                txAsync.when(
                  data: (txs) => txs.isEmpty
                      ? _EmptyTx(palette: palette)
                      : Column(children: txs.take(5).map((t) => _TxRow(tx: t)).toList()),
                  loading: () => const Center(child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )),
                  error: (_, __) => _EmptyTx(palette: palette),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showReceiveSheet(BuildContext context, List<Map<String, dynamic>> accounts) {
    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun compte marchand disponible.')),
      );
      return;
    }
    final merchant = accounts.first;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReceiveSheet(merchant: merchant),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final List<Map<String, dynamic>> accounts;
  const _StatsRow({required this.accounts});

  @override
  Widget build(BuildContext context) {
    final totalVolume = accounts.fold<double>(
        0, (sum, a) => sum + ((a['dailyVolume'] as num?)?.toDouble() ?? 0));
    return Row(
      children: [
        _StatChip(
          label: 'Volume journalier',
          value: Money.format(totalVolume, 'CDF'),
          color: AppColors.cyan,
        ),
        const SizedBox(width: 10),
        _StatChip(
          label: 'Comptes actifs',
          value: '${accounts.length}',
          color: AppColors.green,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(2, (_) => Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 10),
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      )),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: palette.panelAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: AppColors.text, fontSize: 11.5, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final Map<String, dynamic> account;
  const _AccountCard({required this.account});

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.storefront_rounded, color: AppColors.cyan, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(account['name']?.toString() ?? '—',
                    style: const TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w800)),
                Text(account['category']?.toString() ?? '',
                    style: const TextStyle(color: AppColors.textSoft, fontSize: 12)),
              ],
            ),
          ),
          _StatusBadge(status: account['status']?.toString() ?? 'ACTIVE'),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'ACTIVE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isActive ? AppColors.green : AppColors.orange).withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isActive ? 'Actif' : status,
        style: TextStyle(
          color: isActive ? AppColors.green : AppColors.orange,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  final Map<String, dynamic> tx;
  const _TxRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
    final status = tx['status']?.toString() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const Icon(Icons.point_of_sale_rounded, color: AppColors.cyan, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tx['description']?.toString() ?? 'Paiement marchand',
              style: const TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '+ ${Money.format(amount, 'CDF')}',
            style: const TextStyle(color: AppColors.green, fontSize: 13, fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: 8),
          _StatusDot(status: status),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final String status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toUpperCase()) {
      case 'COMPLETED': color = AppColors.green; break;
      case 'PENDING': color = AppColors.gold; break;
      default: color = AppColors.red;
    }
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _EmptyTx extends StatelessWidget {
  final dynamic palette;
  const _EmptyTx({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.receipt_long_rounded, color: AppColors.textSoft, size: 36),
            SizedBox(height: 8),
            Text('Aucune transaction pour l\'instant',
                style: TextStyle(color: AppColors.textSoft, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

Widget _sectionTitle(String title) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
    );

class _ReceiveSheet extends StatefulWidget {
  final Map<String, dynamic> merchant;
  const _ReceiveSheet({required this.merchant});

  @override
  State<_ReceiveSheet> createState() => _ReceiveSheetState();
}

class _ReceiveSheetState extends State<_ReceiveSheet> {
  final _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    final amount = _amountCtrl.text.trim();
    final qrData = 'MBONGO:MERCHANT:${widget.merchant['id']}:${amount.isEmpty ? '0' : amount}';

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Recevoir un paiement',
              style: TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Montant (optionnel)',
              prefixIcon: Icon(Icons.attach_money_rounded),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(data: qrData, version: QrVersions.auto, size: 180),
          ),
          const SizedBox(height: 12),
          Text(
            widget.merchant['name']?.toString() ?? '',
            style: const TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(qrData,
              style: const TextStyle(color: AppColors.textSoft, fontSize: 10),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
