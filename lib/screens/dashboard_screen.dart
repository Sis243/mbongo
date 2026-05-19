import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/mbongo_theme.dart';
import '../services/local_bank_service.dart';
import '../widgets/action_tile.dart';
import '../widgets/common/mbongo_money_particles.dart';
import '../widgets/mbongo_card.dart';
import '../widgets/txn_tile.dart';
import 'appro/appro_mbongo_screen.dart';
import 'airtime/buy_airtime_screen.dart';
import 'cards/virtual_cards_screen.dart';
import 'request_money/request_money_screen.dart';
import 'transactions_screen.dart';
import 'transfer/send_money_screen.dart';
import 'tv/tv_subscription_screen.dart';
import 'withdraw/withdraw_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String money(num n) {
    return n.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ',
        );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>>(
      valueListenable: LocalBankService.currentUser,
      builder: (context, user, _) {
        final palette = MbongoThemeController.current;
        final wallet = (user['wallet'] as Map<String, dynamic>?) ?? {};
        final name = (user['name'] ?? 'Client').toString();
        final balance = (wallet['balance'] ?? 0).toDouble();
        final currency = (wallet['currency'] ?? 'CDF').toString();

        return Scaffold(
          backgroundColor: palette.shellBottom,
          appBar: AppBar(
            backgroundColor: palette.shellTop,
            foregroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: const Text('Tableau de bord'),
            actions: [
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Aucune nouvelle notification.'),
                    ),
                  );
                },
                icon: const Icon(Icons.notifications_none_rounded),
              ),
            ],
          ),
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
                child: MbongoMoneyParticles(
                  color: palette.accent,
                  count: 19,
                  opacity: 0.11,
                ),
              ),
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Bonjour, $name',
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Gerez vos finances et suivez vos mouvements en temps reel.',
                    style: TextStyle(
                      color: AppColors.textSoft,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  MbongoCard(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: palette.bannerGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.account_balance_rounded,
                                color: palette.accentStrong,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Compte principal',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            '${money(balance)} $currency',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Solde disponible',
                            style: TextStyle(
                              color: AppColors.textSoft,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.9,
                    children: [
                      ActionTile(
                        icon: Icons.swap_horiz_rounded,
                        label: 'Transfert',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SendMoneyScreen(),
                            ),
                          );
                        },
                      ),
                      ActionTile(
                        icon: Icons.request_page_rounded,
                        label: 'Demande',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RequestMoneyScreen(),
                            ),
                          );
                        },
                      ),
                      ActionTile(
                        icon: Icons.download_rounded,
                        label: 'Retrait',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WithdrawScreen(),
                            ),
                          );
                        },
                      ),
                      ActionTile(
                        icon: Icons.credit_card_rounded,
                        label: 'Cartes',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const VirtualCardsScreen(),
                            ),
                          );
                        },
                      ),
                      ActionTile(
                        icon: Icons.phone_android_rounded,
                        label: 'Unites',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BuyAirtimeScreen(),
                            ),
                          );
                        },
                      ),
                      ActionTile(
                        icon: Icons.tv_rounded,
                        label: 'TV',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TvSubscriptionScreen(),
                            ),
                          );
                        },
                      ),
                      ActionTile(
                        icon: Icons.receipt_long_rounded,
                        label: 'Historique',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TransactionsScreen(),
                            ),
                          );
                        },
                      ),
                      ActionTile(
                        icon: Icons.qr_code_rounded,
                        label: 'QR Pay',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('QR paiement bientot disponible.'),
                            ),
                          );
                        },
                      ),
                      ActionTile(
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'Depot',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ApproMbongoScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Dernieres transactions',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<List<Map<String, dynamic>>>(
                    valueListenable: LocalBankService.transactions,
                    builder: (context, txs, _) {
                      final recent = txs.take(5).toList();

                      if (recent.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: palette.panelAlt,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Text(
                            'Aucune transaction pour le moment.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.darkMuted,
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: recent
                            .map(
                              (t) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: TxnTile(txn: t),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
