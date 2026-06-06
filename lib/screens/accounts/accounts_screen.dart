import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../features/auth/presentation/auth_notifier.dart';
import '../../features/cards/presentation/card_notifier.dart';
import '../../features/wallet/presentation/wallet_notifier.dart';
import '../../services/api_service.dart';
import '../../widgets/common/mbongo_money_particles.dart';
import '../../widgets/common/transaction_confirm_sheet.dart';
import '../../core/utils/money.dart';
import '../cards/virtual_cards_screen.dart';
import '../transactions_screen.dart';
import '../transfer/send_money_screen.dart';

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  final Set<String> _hiddenCurrencies = <String>{};
  List<Map<String, dynamic>> _linkedBankAccounts = [];
  bool _loadingLinked = false;

  @override
  void initState() {
    super.initState();
    _loadLinkedAccounts();
  }

  Future<void> _loadLinkedAccounts() async {
    setState(() => _loadingLinked = true);
    try {
      final accounts = await ApiService.getLinkedBankAccounts();
      if (mounted) setState(() => _linkedBankAccounts = accounts);
    } catch (_) {}
    if (mounted) setState(() => _loadingLinked = false);
  }

  String _money(num value, String currency) {
    final formatted = value.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]} ',
    );
    return currency == 'USD' ? '\$ $formatted' : 'CDF $formatted';
  }


  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;

    return Scaffold(
      backgroundColor: Colors.transparent,
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
                count: 18,
                opacity: 0.10,
              ),
            ),
          ),
          Builder(
            builder: (context) {
              final currentUser = ref.watch(authProvider).valueOrNull;
              final walletData = ref.watch(walletProvider).valueOrNull;
              final cards = ref.watch(cardProvider).valueOrNull ?? [];

              final clientName = currentUser?.name ?? 'Client';
              final allTxs = (walletData?.transactions ?? [])
                  .map((t) => t.toMap())
                  .toList();
              final recent = allTxs.take(4).toList();
              final credits = walletData?.totalIncoming ?? 0.0;
              final debits = walletData?.totalOutgoing ?? 0.0;



              return RefreshIndicator(
                onRefresh: () async {
                  await ref.read(walletProvider.notifier).refresh();
                  ref.invalidate(cardProvider);
                  await _loadLinkedAccounts();
                },
                child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                children: [
                  _buildHeader(clientName, palette),
                  const SizedBox(height: 18),
                  _buildOverview(
                    credits,
                    debits,
                    _linkedBankAccounts.length,
                    cards.length,
                    palette,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _quickAction(
                          title: 'Transferer',
                          subtitle: 'Virement rapide',
                          icon: Icons.send_rounded,
                          color: palette.accent,
                          palette: palette,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SendMoneyScreen())),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _quickAction(
                          title: 'Cartes',
                          subtitle: cards.isEmpty ? 'Activer' : '${cards.length} activees',
                          icon: Icons.credit_card_rounded,
                          color: palette.accentStrong,
                          palette: palette,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VirtualCardsScreen())),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _buildLinkedBankSection(palette),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Derniers mouvements',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TransactionsScreen(),
                            ),
                          );
                        },
                        child: const Text('Tout voir'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (recent.isEmpty)
                    _emptyRecent(palette)
                  else
                    ...recent.map((tx) => _recentTile(tx, palette)),
                ],
              ),
            );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String clientName, MbongoThemePalette palette) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette.bannerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: palette.glow.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comptes',
            style: TextStyle(
              color: palette.accent,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Structure financiere de $clientName',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Vos comptes bancaires liés à MBONGO. Gérez, transférez et consultez vos soldes.',
            style: TextStyle(
              color: AppColors.textSoft,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverview(
    double credits,
    double debits,
    int cardCount,
    int accountCount,
    MbongoThemePalette palette,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _overviewCell('Entrees', _money(credits, 'CDF'), AppColors.green),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _overviewCell('Sorties', _money(debits, 'CDF'), AppColors.orange),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _overviewCell('Comptes', accountCount.toString(), AppColors.cyan),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _overviewCell('Cartes', cardCount.toString(), palette.accentStrong),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _overviewCell(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MbongoThemeController.current.panelAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAction({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required MbongoThemePalette palette,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              palette.cardGradient.first.withValues(alpha: 0.96),
              palette.cardGradient.last.withValues(alpha: 0.96),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSoft,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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

  Widget _emptyRecent(MbongoThemePalette palette) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text(
        'Aucun mouvement recent.',
        style: TextStyle(
          color: AppColors.darkMuted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _recentTile(Map<String, dynamic> tx, MbongoThemePalette palette) {
    final isCredit = (tx['isCredit'] ?? false) == true;
    final amount = ((tx['amount'] ?? 0) as num).toDouble();
    final currency = (tx['currency'] ?? 'CDF').toString();
    final label = (tx['label'] ?? 'Transaction').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: (isCredit ? AppColors.green : AppColors.primary)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isCredit ? Icons.call_received_rounded : Icons.call_made_rounded,
              color: isCredit ? AppColors.green : AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.darkText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${isCredit ? '+' : '-'} ${_money(amount, currency)}',
            style: TextStyle(
              color: isCredit ? AppColors.green : AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedBankSection(MbongoThemePalette palette) {
    // Totaux par devise
    double totalCdf = 0, totalUsd = 0;
    for (final acc in _linkedBankAccounts) {
      final bal = ((acc['balance'] ?? 0) as num).toDouble();
      if ((acc['currency']?.toString() ?? 'CDF') == 'USD') { totalUsd += bal; } else { totalCdf += bal; }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête section
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mes Comptes CADECO', style: TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  if (_linkedBankAccounts.isNotEmpty)
                    Text(
                      '${_linkedBankAccounts.length} compte${_linkedBankAccounts.length > 1 ? 's' : ''}'
                      '${totalCdf > 0 ? ' · CDF ${_money(totalCdf, "CDF")}' : ''}'
                      '${totalUsd > 0 ? ' · \$ ${totalUsd.toStringAsFixed(2)}' : ''}',
                      style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () => _showLinkBankSheet(palette),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Lier'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_loadingLinked)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 2)))
        else if (_linkedBankAccounts.isEmpty)
          _buildEmptyBankAccounts(palette)
        else
          ..._linkedBankAccounts.map((acc) => _buildLinkedBankCard(acc, palette)),
      ],
    );
  }

  Widget _buildEmptyBankAccounts(MbongoThemePalette palette) {
    return GestureDetector(
      onTap: () => _showLinkBankSheet(palette),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: palette.panelAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.3), style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: palette.accent.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.account_balance_rounded, color: palette.accent, size: 26),
            ),
            const SizedBox(height: 14),
            const Text('Aucun compte bancaire lié', style: TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            const Text(
              'Liez votre compte CADECO pour consulter votre solde, effectuer des virements et approvisionner votre wallet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSoft, fontSize: 12.5, height: 1.45),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: AppColors.gold, size: 18),
                  SizedBox(width: 6),
                  Text('Lier un compte CADECO', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkedBankCard(Map<String, dynamic> acc, MbongoThemePalette palette) {
    final currency = acc['currency']?.toString() ?? 'CDF';
    final balance = ((acc['balance'] ?? 0) as num).toDouble();
    final hidden = _hiddenCurrencies.contains('bank_${acc['id']}');
    final displayBalance = hidden ? (currency == 'USD' ? '\$ ••••••••' : 'CDF ••••••••') : _money(balance, currency);
    final isUsd = currency == 'USD';
    final accountType = acc['accountType']?.toString() ?? 'Compte Courant';
    final accountHolder = acc['accountHolder']?.toString() ?? '';
    final accountNumber = acc['accountNumber']?.toString() ?? '';
    final bankName = acc['bankName']?.toString() ?? 'CADECO';

    // Couleurs selon devise
    final cardColors = isUsd
        ? [const Color(0xFF0A1628), const Color(0xFF0D3320), const Color(0xFF0A4520)]
        : [const Color(0xFF0A1628), const Color(0xFF0D1E45), const Color(0xFF0B2870)];
    final accentColor = isUsd ? const Color(0xFFD4A843) : const Color(0xFF4A9FFF);
    final chipColor = isUsd ? const Color(0xFFD4A843) : const Color(0xFFB8C8E8);

    // Formater le numéro de compte lisiblement
    String formatAccNum(String num) {
      final clean = num.replaceAll(RegExp(r'[\s-]'), '');
      if (clean.length >= 8) {
        return '•••• •••• ${clean.substring(clean.length - 4)}';
      }
      return num;
    }

    return Column(
      children: [
        // ── Carte bancaire premium ───────────────────────────────────
        Container(
          margin: const EdgeInsets.only(bottom: 0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: cardColors,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: accentColor.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 12)),
              BoxShadow(color: accentColor.withValues(alpha: 0.08), blurRadius: 40, offset: const Offset(0, 8)),
            ],
          ),
          child: Stack(
            children: [
              // Pattern de fond subtil
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Opacity(
                    opacity: 0.04,
                    child: CustomPaint(painter: _CardPatternPainter(accentColor)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Ligne 1 : banque + devise + actions ──────────
                    Row(
                      children: [
                        // Logo puce
                        Container(
                          width: 36, height: 28,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [chipColor, chipColor.withValues(alpha: 0.7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Stack(
                            children: [
                              Positioned(left: 8, top: 4, child: Container(width: 20, height: 20, decoration: BoxDecoration(color: chipColor.withValues(alpha: 0.4), shape: BoxShape.circle))),
                              Positioned(left: 2, top: 6, child: Container(width: 16, height: 16, decoration: BoxDecoration(color: chipColor.withValues(alpha: 0.25), shape: BoxShape.circle))),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(bankName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                        ),
                        // Badge devise
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: accentColor.withValues(alpha: 0.35)),
                          ),
                          child: Text(currency, style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        ),
                        const SizedBox(width: 4),
                        // Visibilité
                        GestureDetector(
                          onTap: () => setState(() {
                            final key = 'bank_${acc['id']}';
                            if (hidden) { _hiddenCurrencies.remove(key); } else { _hiddenCurrencies.add(key); }
                          }),
                          child: Icon(hidden ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.white38, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // ── Type de compte ───────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: Text(accountType.toUpperCase(), style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                    ),
                    const SizedBox(height: 10),

                    // ── Titulaire ────────────────────────────────────
                    Text(
                      accountHolder,
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 0.3),
                    ),
                    const SizedBox(height: 18),

                    // ── Solde ────────────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('SOLDE DISPONIBLE', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                              const SizedBox(height: 5),
                              Text(
                                displayBalance,
                                style: TextStyle(color: isUsd ? const Color(0xFFD4A843) : Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        ),
                        // Numéro de compte
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('N° COMPTE', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 8.5, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                            const SizedBox(height: 4),
                            Text(formatAccNum(accountNumber), style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Boutons d'action sous la carte ───────────────────────────
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          decoration: BoxDecoration(
            color: palette.panelAlt,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
            border: Border.all(color: accentColor.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _doTransfer(acc, toWallet: true),
                  icon: Icon(Icons.arrow_downward_rounded, size: 15, color: accentColor),
                  label: Text('Compte → Wallet', style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w800)),
                ),
              ),
              Container(width: 1, height: 24, color: AppColors.border.withValues(alpha: 0.3)),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _doTransfer(acc, toWallet: false),
                  icon: Icon(Icons.arrow_upward_rounded, size: 15, color: accentColor),
                  label: Text('Wallet → Compte', style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w800)),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.link_off_rounded, color: AppColors.muted, size: 18),
                onPressed: () => _unlinkAccount(acc['id']?.toString() ?? ''),
                tooltip: 'Délier ce compte',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _doTransfer(Map<String, dynamic> acc, {required bool toWallet}) async {
    final currency = acc['currency']?.toString() ?? 'CDF';
    final accountId = acc['id']?.toString() ?? '';
    final accountName = acc['bankName']?.toString() ?? 'Compte';
    final walletBalance = ref.read(walletProvider).valueOrNull?.balance ?? 0.0;
    final accountBalance = ((acc['balance'] ?? 0) as num).toDouble();
    final amtCtrl = TextEditingController();

    final amount = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _AmountSheet(
        title: toWallet ? 'Compte → Wallet' : 'Wallet → Compte',
        hint: toWallet
            ? 'Dispo: ${Money.format(accountBalance, currency)}'
            : 'Dispo: ${Money.format(walletBalance, currency)}',
        currency: currency,
        controller: amtCtrl,
      ),
    );
    if (amount == null || amount <= 0 || !mounted) return;

    final confirmed = await showTransactionConfirmSheet(
      context: context,
      title: toWallet ? 'Compte → Wallet' : 'Wallet → Compte',
      icon: toWallet ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
      rows: [
        ConfirmRow(label: toWallet ? 'Source' : 'Destination', value: accountName),
        ConfirmRow(label: 'Montant', value: Money.format(amount, currency), bold: true, valueColor: const Color(0xFFD4A843)),
      ],
    );
    if (!confirmed || !mounted) return;

    try {
      if (toWallet) {
        await ApiService.accountToWallet(accountId: accountId, amount: amount);
      } else {
        await ApiService.walletToAccount(accountId: accountId, amount: amount);
      }
      await Future.wait([
        _loadLinkedAccounts(),
        ref.read(walletProvider.notifier).refresh(),
      ]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.green,
            content: Text(toWallet ? 'Transfert vers wallet effectué.' : 'Virement vers compte effectué.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _unlinkAccount(String id) async {
    if (id.isEmpty) return;
    try {
      await ApiService.unlinkBankAccount(id);
      if (mounted) {
        setState(() => _linkedBankAccounts.removeWhere((a) => a['id']?.toString() == id));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  void _showLinkBankSheet(MbongoThemePalette palette) {
    final controller = TextEditingController();
    Map<String, dynamic>? lookupResult;
    bool looking = false;
    bool linking = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
            decoration: BoxDecoration(
              color: palette.panel,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Lier un compte bancaire', style: TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                const Text('Compte CADECO', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    hintText: 'Numéro de compte bancaire',
                    hintStyle: TextStyle(color: AppColors.muted),
                    filled: true,
                    fillColor: palette.panelAlt,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.account_balance_rounded, color: AppColors.muted),
                  ),
                ),
                const SizedBox(height: 14),
                if (lookupResult != null && lookupResult!['exists'] == true) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 18),
                          const SizedBox(width: 8),
                          Text(lookupResult!['bankName']?.toString() ?? 'Banque', style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w900)),
                        ]),
                        const SizedBox(height: 8),
                        Text(lookupResult!['accountHolder']?.toString() ?? '', style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w800, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text('${lookupResult!['accountType']} · ${lookupResult!['currency']}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          _money((lookupResult!['balance'] as num?) ?? 0, lookupResult!['currency']?.toString() ?? 'CDF'),
                          style: const TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ] else if (lookupResult != null && lookupResult!['exists'] == false) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.red.withValues(alpha: 0.3))),
                    child: const Row(children: [
                      Icon(Icons.error_outline_rounded, color: AppColors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Compte introuvable dans le système bancaire.', style: TextStyle(color: AppColors.red, fontSize: 13)),
                    ]),
                  ),
                  const SizedBox(height: 14),
                ],
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: looking ? null : () async {
                        if (controller.text.trim().isEmpty) return;
                        setSheet(() => looking = true);
                        final result = await ApiService.lookupBankAccount(controller.text.trim());
                        setSheet(() { lookupResult = result; looking = false; });
                      },
                      child: looking ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Vérifier'),
                    ),
                  ),
                  if (lookupResult != null && lookupResult!['exists'] == true) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: linking ? null : () async {
                          setSheet(() => linking = true);
                          try {
                            await ApiService.linkBankAccount(controller.text.trim());
                            if (ctx.mounted) Navigator.pop(ctx);
                            await _loadLinkedAccounts();
                          } catch (e) {
                            setSheet(() => linking = false);
                            if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$e')));
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
                        child: linking ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Lier'),
                      ),
                    ),
                  ],
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

// Pattern décoratif de fond sur les cartes bancaires
class _CardPatternPainter extends CustomPainter {
  final Color color;
  const _CardPatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1;
    for (double i = -size.height; i < size.width + size.height; i += 28) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.2), size.height * 0.55, paint..strokeWidth = 0.8);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.2), size.height * 0.75, paint..strokeWidth = 0.5);
  }

  @override
  bool shouldRepaint(_CardPatternPainter old) => old.color != color;
}

class _AmountSheet extends StatelessWidget {
  final String title;
  final String hint;
  final String currency;
  final TextEditingController controller;
  const _AmountSheet({required this.title, required this.hint, required this.currency, required this.controller});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: EdgeInsets.only(left: 12, right: 12, bottom: bottom > 0 ? 0 : 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1A2A3D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, bottom > 0 ? bottom + 16 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(hint, style: const TextStyle(color: Color(0xFF8EACC9), fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                decoration: InputDecoration(
                  labelText: 'Montant ($currency)',
                  labelStyle: const TextStyle(color: Color(0xFF8EACC9)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        final v = double.tryParse(controller.text.trim().replaceAll(',', '.'));
                        Navigator.of(context).pop(v);
                      },
                      child: const Text('Suivant'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
