import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../features/auth/presentation/auth_notifier.dart';
import '../../features/cards/presentation/card_notifier.dart';
import '../../features/wallet/presentation/wallet_notifier.dart';
import '../../models/account_model.dart';
import '../../widgets/common/mbongo_money_particles.dart';
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

  String _money(num value, String currency) {
    final formatted = value.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]} ',
    );
    return currency == 'USD' ? '\$ $formatted' : 'CDF $formatted';
  }

  String _masked(String currency) {
    return currency == 'USD' ? '\$ ********' : 'CDF ********';
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

              final accounts = walletData != null
                  ? [
                      AccountModel(
                        id: walletData.id,
                        type: 'Portefeuille ${walletData.currency}',
                        currency: walletData.currency,
                        number: 'MBONGO-${walletData.currency}',
                        balance: walletData.balance,
                        selected: true,
                      ),
                    ]
                  : <AccountModel>[];

              final productAccounts = [
                _ProductAccount(
                  icon: Icons.savings_rounded,
                  title: 'Compte Épargne',
                  description: 'Épargnez facilement et suivez votre solde en temps réel.',
                  color: const Color(0xFF1FB7FF),
                ),
                _ProductAccount(
                  icon: Icons.account_balance_rounded,
                  title: 'Compte Courant',
                  description: 'Gérez vos opérations quotidiennes depuis votre mobile.',
                  color: const Color(0xFF1B4EAA),
                ),
                _ProductAccount(
                  icon: Icons.corporate_fare_rounded,
                  title: 'Compte CEDEV',
                  description: 'Compte dédié aux services CEDEV.',
                  color: const Color(0xFFF7B731),
                ),
                _ProductAccount(
                  icon: Icons.business_center_rounded,
                  title: 'Compte Entreprise',
                  description: 'Solution adaptée aux activités professionnelles.',
                  color: const Color(0xFF26C6DA),
                ),
                _ProductAccount(
                  icon: Icons.school_rounded,
                  title: 'Compte Jeune',
                  description: 'Conçu pour les jeunes de moins de 25 ans.',
                  color: const Color(0xFF66BB6A),
                ),
                _ProductAccount(
                  icon: Icons.phone_android_rounded,
                  title: 'Compte Mobile',
                  description: 'Accès simplifié depuis votre téléphone.',
                  color: const Color(0xFFAB47BC),
                ),
              ];

              return RefreshIndicator(
                onRefresh: () async {
                  await ref.read(walletProvider.notifier).refresh();
                  ref.invalidate(cardProvider);
                },
                child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                children: [
                  _buildHeader(clientName, palette),
                  const SizedBox(height: 18),
                  _buildOverview(
                    credits,
                    debits,
                    cards.length,
                    accounts.length,
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
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SendMoneyScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _quickAction(
                          title: 'Cartes',
                          subtitle: cards.isEmpty
                              ? 'Activer'
                              : '${cards.length} activees',
                          icon: Icons.credit_card_rounded,
                          color: palette.accentStrong,
                          palette: palette,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const VirtualCardsScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Mon portefeuille actif',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (accounts.isEmpty)
                    _emptyAccounts(palette)
                  else
                    ...accounts.map((account) => _buildAccountCard(account, palette)),
                  const SizedBox(height: 22),
                  const Text(
                    'Produits disponibles',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ouvrez un compte adapté à vos besoins.',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...productAccounts.map((p) => _buildProductCard(p, palette)),
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
            'Vue de synthese des comptes, des cartes et des derniers mouvements.',
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

  Widget _buildAccountCard(AccountModel account, MbongoThemePalette palette) {
    final hidden = _hiddenCurrencies.contains(account.currency);
    final color = account.currency == 'USD' ? palette.accentStrong : palette.accent;
    final amount =
        hidden ? _masked(account.currency) : _money(account.balance, account.currency);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.cardGradient.first,
            palette.cardGradient.last,
            color.withValues(alpha: 0.18),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.36)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  account.currency == 'USD'
                      ? Icons.attach_money_rounded
                      : Icons.account_balance_wallet_rounded,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.type,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      account.number,
                      style: const TextStyle(
                        color: Color(0xFFD6E2FF),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    if (hidden) {
                      _hiddenCurrencies.remove(account.currency);
                    } else {
                      _hiddenCurrencies.add(account.currency);
                    }
                  });
                },
                icon: Icon(
                  hidden ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              account.currency == 'USD' ? 'Compte international' : 'Compte principal',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            amount,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            account.currency == 'USD'
                ? 'Compte de liquidite internationale'
                : 'Compte de disponibilite locale',
            style: const TextStyle(
              color: Color(0xFFD6E2FF),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyAccounts(MbongoThemePalette palette) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text(
        'Aucun compte visible pour le moment.',
        style: TextStyle(
          color: AppColors.darkMuted,
          fontWeight: FontWeight.w700,
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

  Widget _buildProductCard(_ProductAccount p, MbongoThemePalette palette) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: p.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(p.icon, color: p.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.title,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  p.description,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: p.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Ouvrir',
              style: TextStyle(
                color: p.color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductAccount {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _ProductAccount({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
