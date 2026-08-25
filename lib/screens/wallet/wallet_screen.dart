import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../core/utils/money.dart';
import '../../features/wallet/domain/wallet_state.dart';
import '../../features/wallet/presentation/wallet_notifier.dart';
import '../../models/account_model.dart';
import '../../services/kyc_guard_service.dart';
import '../../widgets/cards/wallet_card.dart';
import '../../widgets/common/mbongo_money_particles.dart';
import '../deposit/deposit_method_screen.dart';
import '../exchange/exchange_money_screen.dart';
import '../profile/kyc_status_screen.dart';
import '../profile/share_profile_screen.dart';
import '../request_money/request_money_screen.dart';
import '../transactions_screen.dart';
import '../transfer/send_money_screen.dart';
import '../withdraw/withdraw_screen.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  String _kycStatus = 'non_commence';
  bool _hideBalance = false;

  @override
  void initState() {
    super.initState();
    _loadKyc();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletProvider.notifier).refresh();
    });
  }

  Future<void> _loadKyc() async {
    final status = await KycGuardService.syncRemoteStatus();
    if (!mounted) return;
    setState(() => _kycStatus = status);
  }

  Future<void> _guardedNavigate(Widget screen) async {
    final access = await KycGuardService.sensitiveOperationAccess();
    if (!mounted) return;
    if (access.allowed) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    } else {
      _showKycBlock(access.message);
    }
  }

  void _showKycBlock(String message) {
    final palette = MbongoThemeController.current;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: palette.panel,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.36)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Row(children: [
            Icon(Icons.lock_rounded, color: AppColors.gold),
            SizedBox(width: 10),
            Expanded(child: Text('Opération bloquée', style: TextStyle(color: AppColors.text, fontSize: 17, fontWeight: FontWeight.w900))),
          ]),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: AppColors.textSoft, fontSize: 14, height: 1.4)),
          const SizedBox(height: 18),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const KycStatusScreen())); },
            child: const Text('Voir mon dossier KYC'),
          )),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer'))),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletProvider);
    final palette = MbongoThemeController.current;
    final walletData = walletAsync.valueOrNull;

    final mainWallet = walletData != null
        ? AccountModel(id: walletData.id, type: 'Wallet MBONGO', currency: walletData.currency, number: 'MBONGO-${walletData.currency}', balance: walletData.balance, selected: true)
        : AccountModel(id: '', type: 'Wallet MBONGO', currency: 'CDF', number: 'MBONGO-CDF', balance: 0, selected: true);

    final extraWallets = walletData?.extraBalances ?? [];
    final txs = (walletData?.transactions ?? []).take(6).toList();
    final inflow = walletData?.totalIncoming ?? 0.0;
    final outflow = walletData?.totalOutgoing ?? 0.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(children: [
        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [palette.shellTop, palette.shellBottom]),
        ))),
        Positioned.fill(child: IgnorePointer(child: MbongoMoneyParticles(color: palette.accentStrong, count: 18, opacity: 0.10))),
        RefreshIndicator(
          onRefresh: () => ref.read(walletProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
            children: [
              // ── KYC banner ──────────────────────────────────────────
              if (_kycStatus != 'valide') ...[_buildKycBanner(palette), const SizedBox(height: 14)],

              // ── Titre section ────────────────────────────────────────
              Row(children: [
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Mes Wallets', style: TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w900)),
                  SizedBox(height: 2),
                  Text('Portefeuilles électroniques MBONGO', style: TextStyle(color: AppColors.textSoft, fontSize: 12)),
                ])),
                IconButton(
                  icon: Icon(_hideBalance ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: AppColors.muted),
                  onPressed: () => setState(() => _hideBalance = !_hideBalance),
                ),
              ]),
              const SizedBox(height: 14),

              // ── Wallet principal (CDF) ───────────────────────────────
              WalletCard(wallet: mainWallet, gradient: palette.cardGradient),

              // ── Wallets supplémentaires (USD etc.) ───────────────────
              if (extraWallets.isNotEmpty) ...[
                const SizedBox(height: 10),
                ...extraWallets.map((b) => _buildExtraWalletCard(b, palette)),
              ],
              const SizedBox(height: 20),

              // ── Synthèse ─────────────────────────────────────────────
              _buildSummaryRow(mainWallet.balance, inflow, outflow, mainWallet.currency, palette),
              const SizedBox(height: 20),

              // ── Actions rapides ──────────────────────────────────────
              _buildActions(palette),
              const SizedBox(height: 20),

              // ── Bouton recevoir / QR ─────────────────────────────────
              _buildReceiveButton(palette),
              const SizedBox(height: 20),

              // ── Mouvements récents ───────────────────────────────────
              _buildTransactions(txs, mainWallet.currency, palette),
            ],
          ),
        ),
      ]),
    );
  }

  // ── Wallet USD card ────────────────────────────────────────────────────
  Widget _buildExtraWalletCard(Map<String, dynamic> b, MbongoThemePalette palette) {
    final currency = b['currency']?.toString() ?? 'USD';
    final balance = ((b['balance'] ?? b['amount'] ?? 0) as num).toDouble();
    final isUsd = currency == 'USD';
    final color = isUsd ? const Color(0xFFD4A843) : AppColors.cyan;

    final extraModel = AccountModel(id: 'extra-$currency', type: 'Wallet MBONGO', currency: currency, number: 'MBONGO-$currency', balance: balance, selected: false);
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: WalletCard(
        wallet: extraModel,
        gradient: [palette.cardGradient.first, color.withValues(alpha: 0.25), palette.cardGradient.last],
      ),
    );
  }

  // ── Synthèse 3 métriques ───────────────────────────────────────────────
  Widget _buildSummaryRow(double balance, double inflow, double outflow, String currency, MbongoThemePalette palette) {
    return Row(children: [
      Expanded(child: _metricCard('Disponible', _hideBalance ? '••••' : Money.format(balance, currency), palette.accent, palette)),
      const SizedBox(width: 10),
      Expanded(child: _metricCard('Reçu', _hideBalance ? '••••' : Money.format(inflow, currency), AppColors.green, palette)),
      const SizedBox(width: 10),
      Expanded(child: _metricCard('Dépensé', _hideBalance ? '••••' : Money.format(outflow, currency), AppColors.orange, palette)),
    ]);
  }

  Widget _metricCard(String label, String value, Color color, MbongoThemePalette palette) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: AppColors.textSoft, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  // ── Actions 2×2 ────────────────────────────────────────────────────────
  Widget _buildActions(MbongoThemePalette palette) {
    final actions = [
      (Icons.north_east_rounded,  'Envoyer',  palette.accent,       () => _guardedNavigate(const SendMoneyScreen())),
      (Icons.south_west_rounded,  'Recevoir', AppColors.green,       () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestMoneyScreen()))),
      (Icons.add_rounded,         'Déposer',  AppColors.cyan,        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DepositMethodScreen()))),
      (Icons.download_rounded,    'Retirer',  AppColors.orange,      () => _guardedNavigate(const WithdrawScreen())),
      (Icons.currency_exchange_rounded, 'Changer', palette.accentStrong, () => _guardedNavigate(const ExchangeMoneyScreen())),
      (Icons.list_alt_rounded,    'Historique', AppColors.muted,     () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionsScreen()))),
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Actions', style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w900)),
      const SizedBox(height: 12),
      GridView.builder(
        itemCount: actions.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          mainAxisExtent: 82,
        ),
        itemBuilder: (_, i) {
          final a = actions[i];
          return InkWell(
            onTap: a.$4,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              decoration: BoxDecoration(
                color: palette.panelAlt,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: a.$3.withValues(alpha: 0.2)),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: a.$3.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                  child: Icon(a.$1, color: a.$3, size: 20),
                ),
                const SizedBox(height: 6),
                Text(a.$2, style: const TextStyle(color: AppColors.text, fontSize: 11, fontWeight: FontWeight.w800)),
              ]),
            ),
          );
        },
      ),
    ]);
  }

  // ── Bouton recevoir ────────────────────────────────────────────────────
  Widget _buildReceiveButton(MbongoThemePalette palette) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShareProfileScreen())),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.green.withValues(alpha: 0.08), palette.panelAlt], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.green.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.qr_code_rounded, color: AppColors.green, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Mon QR de réception', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w900, fontSize: 14)),
            SizedBox(height: 2),
            Text('Partagez pour recevoir un virement ou paiement', style: TextStyle(color: AppColors.textSoft, fontSize: 12)),
          ])),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ]),
      ),
    );
  }

  // ── Transactions récentes ──────────────────────────────────────────────
  Widget _buildTransactions(List<TxEntry> txs, String currency, MbongoThemePalette palette) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(child: Text('Derniers mouvements', style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w900))),
        TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionsScreen())),
          child: const Text('Voir tout'),
        ),
      ]),
      const SizedBox(height: 8),
      if (txs.isEmpty)
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(color: palette.panelAlt, borderRadius: BorderRadius.circular(16)),
          child: const Center(child: Text('Aucun mouvement récent.', style: TextStyle(color: AppColors.muted))),
        )
      else
        ...txs.map((tx) => _txTile(tx, palette)),
    ]);
  }

  Widget _txTile(TxEntry tx, MbongoThemePalette palette) {
    final isCredit = tx.isCredit;
    final color = isCredit ? AppColors.green : AppColors.orange;
    final sign = isCredit ? '+' : '-';
    final typeLabel = _labelForType(tx.type);
    final dateStr = '${tx.date.day.toString().padLeft(2,'0')}/${tx.date.month.toString().padLeft(2,'0')} ${tx.date.hour.toString().padLeft(2,'0')}:${tx.date.minute.toString().padLeft(2,'0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.18)),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12)),
          child: Icon(isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(typeLabel, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w800, fontSize: 13)),
          if (tx.motif.isNotEmpty)
            Text(tx.motif, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSoft, fontSize: 11.5)),
          Text(dateStr, style: const TextStyle(color: AppColors.muted, fontSize: 10.5)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('$sign ${Money.format(tx.amount, tx.currency)}', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: tx.status.toUpperCase() == 'SUCCESS' ? AppColors.green.withValues(alpha: 0.10) : AppColors.orange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(tx.status.toUpperCase() == 'SUCCESS' ? 'OK' : tx.status, style: TextStyle(color: tx.status.toUpperCase() == 'SUCCESS' ? AppColors.green : AppColors.orange, fontSize: 9.5, fontWeight: FontWeight.w800)),
          ),
        ]),
      ]),
    );
  }

  String _labelForType(String type) {
    if (type.startsWith('transfer')) return 'Virement';
    if (type.contains('deposit') || type.contains('add-money')) return 'Dépôt';
    if (type.contains('withdraw')) return 'Retrait';
    if (type.contains('airtime')) return 'Recharge';
    if (type.contains('tv')) return 'Abonnement TV';
    if (type.contains('merchant') || type.contains('pos')) return 'Paiement marchand';
    if (type.contains('bill')) return 'Paiement facture';
    if (type.contains('account_to_wallet')) return 'Compte → Wallet';
    if (type.contains('wallet_to_account')) return 'Wallet → Compte';
    if (type.contains('request') || type.contains('demande')) return 'Demande d\'argent';
    return type.isNotEmpty ? type[0].toUpperCase() + type.substring(1) : 'Transaction';
  }

  Widget _buildKycBanner(MbongoThemePalette palette) {
    final label = switch (_kycStatus) {
      'en_attente' => 'Dossier KYC en cours de vérification.',
      'refuse' => 'Dossier KYC refusé. Reprenez le dossier.',
      _ => 'Complétez votre vérification KYC pour débloquer les opérations.',
    };
    final color = _kycStatus == 'refuse' ? AppColors.red : AppColors.gold;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KycStatusScreen())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.36))),
        child: Row(children: [
          Icon(Icons.info_rounded, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700))),
          Icon(Icons.chevron_right_rounded, color: color, size: 18),
        ]),
      ),
    );
  }
}
