import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../core/utils/money.dart';
import '../../features/wallet/domain/wallet_state.dart';
import '../../features/wallet/presentation/wallet_notifier.dart';
import '../../models/account_model.dart';
import '../../widgets/cards/wallet_card.dart';
import '../../widgets/common/mbongo_money_particles.dart';
import '../exchange/exchange_money_screen.dart';
import '../request_money/request_money_screen.dart';
import '../transfer/send_money_screen.dart';
import '../withdraw/withdraw_screen.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  AccountModel _toAccountModel(WalletData walletData) => AccountModel(
        id: walletData.id,
        type: 'Portefeuille ${walletData.currency}',
        currency: walletData.currency,
        number: 'MBONGO-${walletData.currency}',
        balance: walletData.balance,
        selected: true,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider);
    final palette = MbongoThemeController.current;
    final walletData = walletAsync.valueOrNull;

    final currentWallet = walletData != null
        ? _toAccountModel(walletData)
        : AccountModel(
            id: '',
            type: 'Portefeuille CDF',
            currency: 'CDF',
            number: 'MBONGO-CDF',
            balance: 0,
            selected: true,
          );

    final transactions = (walletData?.transactions ?? [])
        .where((t) => t.currency == currentWallet.currency)
        .take(5)
        .map((t) => t.toMap())
        .toList();

    final inflow = walletData?.totalIncoming ?? 0.0;
    final outflow = walletData?.totalOutgoing ?? 0.0;

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
                color: palette.accentStrong,
                count: 18,
                opacity: 0.10,
              ),
            ),
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
            children: [
              _buildHeader(currentWallet, palette),
              const SizedBox(height: 18),
              WalletCard(
                wallet: currentWallet,
                gradient: palette.cardGradient,
              ),
              const SizedBox(height: 18),
              _buildWalletBoard(currentWallet, inflow, outflow, palette),
              const SizedBox(height: 18),
              _buildActionMatrix(context, palette),
              const SizedBox(height: 18),
              _buildHealthStrip(currentWallet, palette),
              const SizedBox(height: 18),
              _buildTransactionFeed(
                  transactions, currentWallet.currency, palette),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(dynamic currentWallet, MbongoThemePalette palette) {
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
            'Portefeuille',
            style: TextStyle(
              color: palette.accent,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Solde ${currentWallet.currency}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Vos mouvements et actions rapides',
            style: TextStyle(
              color: AppColors.textSoft,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletBoard(
    dynamic currentWallet,
    double inflow,
    double outflow,
    MbongoThemePalette palette,
  ) {
    final reserve = currentWallet.balance * 0.25;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _metricTile(
                  'Disponible',
                  Money.format(currentWallet.balance, currentWallet.currency),
                  palette.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricTile(
                  'Reserve',
                  Money.format(reserve, currentWallet.currency),
                  AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _metricTile(
                  'Entrees recentes',
                  Money.format(inflow, currentWallet.currency),
                  AppColors.green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricTile(
                  'Sorties recentes',
                  Money.format(outflow, currentWallet.currency),
                  AppColors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value, Color color) {
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
              color: AppColors.darkMuted,
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

  Widget _buildActionMatrix(BuildContext context, MbongoThemePalette palette) {
    final items = [
      (
        'Envoyer',
        Icons.north_east_rounded,
        palette.accent,
        const SendMoneyScreen(),
      ),
      (
        'Recevoir',
        Icons.south_west_rounded,
        AppColors.green,
        const RequestMoneyScreen(),
      ),
      (
        'Changer',
        Icons.currency_exchange_rounded,
        palette.accentStrong,
        const ExchangeMoneyScreen(),
      ),
      (
        'Retirer',
        Icons.download_rounded,
        AppColors.orange,
        const WithdrawScreen(),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions',
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 92,
          ),
          itemBuilder: (_, index) {
            final item = items[index];
            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => item.$4),
                );
              },
              child: Ink(
                padding: const EdgeInsets.all(14),
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
                        color: item.$3.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(item.$2, color: item.$3),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.$1,
                        style: const TextStyle(
                          color: AppColors.darkText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHealthStrip(dynamic wallet, MbongoThemePalette palette) {
    final available = wallet.balance;
    final status = available > 100 ? 'Bon niveau' : 'A surveiller';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.monitor_heart_rounded, color: palette.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Disponibilite: $status',
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Vue simple du niveau actuel de votre portefeuille.',
                  style: TextStyle(
                    color: AppColors.darkMuted,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionFeed(
    List<Map<String, dynamic>> txs,
    String currency,
    MbongoThemePalette palette,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Journal recent',
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        if (txs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: palette.panelAlt,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              'Aucun mouvement recent sur ce portefeuille.',
              style: TextStyle(
                color: AppColors.darkMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        else
          ...txs.map((tx) {
            final isCredit = (tx['isCredit'] ?? false) == true;
            final amount = ((tx['amount'] ?? 0) as num).toDouble();
            final label = (tx['label'] ?? 'Transaction').toString();
            final reason = (tx['motif'] ?? '').toString();

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.panel,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    isCredit ? Icons.add_circle_rounded : Icons.remove_circle_rounded,
                    color: isCredit ? AppColors.green : AppColors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (reason.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            reason,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${isCredit ? '+' : '-'} ${Money.format(amount, currency)}',
                    style: TextStyle(
                      color: isCredit ? AppColors.green : AppColors.gold,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
