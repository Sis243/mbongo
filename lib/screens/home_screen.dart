import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/mbongo_theme.dart';
import '../features/auth/presentation/auth_notifier.dart';
import '../features/notifications/presentation/notifications_provider.dart';
import '../features/wallet/presentation/wallet_notifier.dart';
import '../models/service_item.dart';
import '../store/mbongo_store.dart';
import '../widgets/common/mbongo_money_particles.dart';
import '../widgets/home/banner_carousel.dart';
import '../widgets/home/service_tile.dart';
import 'airtime/buy_airtime_screen.dart';
import 'appro/appro_mbongo_screen.dart';
import 'cards/virtual_cards_screen.dart';
import 'exchange/exchange_money_screen.dart';
import 'login_screen.dart';
import 'exchange_rates/exchange_rates_screen.dart';
import 'notifications/notifications_screen.dart';
import 'request_money/request_money_screen.dart';
import 'transactions_screen.dart';
import 'transfer/send_money_screen.dart';
import 'merchant/merchant_payment_screen.dart';
import 'transfer/transfer_international_screen.dart';
import 'wallet/wallet_screen.dart';
import 'tv/tv_subscription_screen.dart';
import 'withdraw/withdraw_screen.dart';
import 'bill_pay/bill_pay_screen.dart';
import 'profile/share_profile_screen.dart';
import 'qr/qr_scan_router.dart';
import '../services/kyc_guard_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletProvider.notifier).refresh();
    });
  }

  String _money(num value) {
    return value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]} ',
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletProvider);
    final currentUser = ref.watch(authProvider).valueOrNull;

    final services = <ServiceItem>[
      ServiceItem(title: 'Envoyer', icon: Icons.send_rounded),
      ServiceItem(title: 'Demander', icon: Icons.request_quote_rounded),
      ServiceItem(title: 'Changer', icon: Icons.currency_exchange_rounded),
      ServiceItem(title: 'International', icon: Icons.public_rounded),
      ServiceItem(title: 'Retirer', icon: Icons.download_rounded, isNew: true),
      ServiceItem(title: 'Mes cartes', icon: Icons.credit_card_rounded),
      ServiceItem(title: 'Unites', icon: Icons.phone_android_rounded),
      ServiceItem(title: 'Abonnement TV', icon: Icons.tv_rounded),
      ServiceItem(title: 'Deposer', icon: Icons.account_balance_wallet_rounded),
      ServiceItem(title: 'Taux de change', icon: Icons.currency_exchange_rounded),
      ServiceItem(title: 'Payer', icon: Icons.storefront_rounded, isNew: true),
      ServiceItem(title: 'Factures', icon: Icons.receipt_long_rounded, isNew: true),
      ServiceItem(title: 'Scanner QR', icon: Icons.qr_code_scanner_rounded, isNew: true),
      ServiceItem(title: 'Mon QR', icon: Icons.qr_code_rounded),
    ];

    final wallet = walletAsync.valueOrNull;
    final balance = wallet?.balance ?? 0.0;
    final currency = wallet?.currency ?? 'CDF';
    final profile = currentUser?.name ?? 'Client';
    final palette = MbongoThemeController.current;
    final txs = wallet?.transactions
            .map((t) => t.toMap())
            .toList() ??
        [];
    final outgoing = wallet?.totalOutgoing ?? 0.0;
    final incoming = wallet?.totalIncoming ?? 0.0;
    final latest = txs.take(4).toList();
    final pendingValidations = wallet?.pendingCount ?? 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: MbongoMoneyParticles(
                        color: palette.accent,
                        count: 16,
                        opacity: 0.08,
                        height: 0,
                      ),
                    ),
                  ),
                  RefreshIndicator(
                    onRefresh: () => ref.read(walletProvider.notifier).refresh(),
                    child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                    children: [
                      _buildTopBar(context, ref, profile, palette),
                      const SizedBox(height: 14),
                      BannerCarousel(banners: MbongoStore.banners),
                      const SizedBox(height: 18),
                      if (walletAsync.isLoading && wallet == null)
                        _buildShimmerCard(palette)
                      else
                        _buildBalanceCard(
                          balance: balance,
                          currency: currency,
                          transactionCount: txs.length,
                          incoming: incoming,
                          outgoing: outgoing,
                          pendingValidations: pendingValidations,
                          palette: palette,
                        ),
                      const SizedBox(height: 16),
                      _buildQuickStrip(context, profile, currency, palette),
                      const SizedBox(height: 18),
                      _buildSectionTitle('Nos services'),
                      const SizedBox(height: 12),
                      GridView.builder(
                        itemCount: services.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 112,
                        ),
                        itemBuilder: (_, index) {
                          final item = services[index];
                          return ServiceTile(
                            item: item,
                            iconColor: _iconColor(item.title, palette),
                            onTap: () => _onServiceTap(item.title),
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      _buildSectionTitle('Activite recente'),
                      const SizedBox(height: 12),
                      if (walletAsync.isLoading && wallet == null)
                        ...[1, 2, 3].map((_) => _buildShimmerTile(palette))
                      else if (latest.isEmpty)
                        _buildEmptyState()
                      else
                        ...latest.map(_ActivityTile.new),
                      const SizedBox(height: 12),
                      _buildFooterCard(palette),
                    ],
                  ),
                  ),
        ],
      ),
    );
  }

  Widget _buildShimmerCard(MbongoThemePalette palette) {
    return Shimmer.fromColors(
      baseColor: palette.panelAlt,
      highlightColor: palette.panel,
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: palette.panelAlt,
          borderRadius: BorderRadius.circular(22),
        ),
      ),
    );
  }

  Widget _buildShimmerTile(MbongoThemePalette palette) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Shimmer.fromColors(
        baseColor: palette.panelAlt,
        highlightColor: palette.panel,
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: palette.panelAlt,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    WidgetRef ref,
    String profile,
    MbongoThemePalette palette,
  ) {
    final unreadAsync = ref.watch(unreadCountProvider);
    final unreadCount = unreadAsync.valueOrNull ?? 0;

    return Row(
        children: [
          Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Image.asset(
              'assets/icon/mbongo.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(
                'MBONGO',
                style: TextStyle(
                  color: palette.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Bonjour, $profile',
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
              icon: const Icon(Icons.notifications_rounded, color: AppColors.text),
            ),
            if (unreadCount > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: palette.shellTop, width: 1.5),
                  ),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
        IconButton(
          onPressed: () => _showQuickMenu(context, ref),
          icon: const Icon(Icons.tune_rounded, color: AppColors.text),
        ),
      ],
    );
  }

  Widget _buildBalanceCard({
    required double balance,
    required String currency,
    required int transactionCount,
    required double incoming,
    required double outgoing,
    required int pendingValidations,
    required MbongoThemePalette palette,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette.cardGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Mon portefeuille',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Direct',
                  style: TextStyle(
                    color: AppColors.textSoft,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            currency == 'USD' ? '\$ ${_money(balance)}' : 'CDF ${_money(balance)}',
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 31,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Solde disponible',
                style: TextStyle(
                  color: AppColors.textSoft,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                pendingValidations == 0
                    ? 'Tout est valide'
                    : '$pendingValidations en attente',
                style: TextStyle(
                  color: pendingValidations == 0 ? AppColors.textSoft : palette.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _signalTile(
                  'Transactions',
                  transactionCount.toString(),
                  palette.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _signalTile('Credits', _money(incoming), AppColors.green)),
              const SizedBox(width: 10),
              Expanded(child: _signalTile('Debits', _money(outgoing), AppColors.gold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _signalTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSoft,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStrip(
    BuildContext context,
    String profile,
    String currency,
    MbongoThemePalette palette,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: palette.panelAlt,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'En un instant',
                  style: TextStyle(
                    color: AppColors.darkMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Envoyez, recevez et payez.',
                  style: TextStyle(
                    color: AppColors.darkText,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$profile - $currency',
                  style: const TextStyle(
                    color: AppColors.darkMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TransactionsScreen()),
                      );
                    },
                    child: const Text('Voir mes mouvements'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: palette.panel,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified_user_rounded, color: AppColors.gold),
                const SizedBox(height: 14),
                const Text(
                  'Disponible 24h/24',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rapide, securise et fiable',
                  style: TextStyle(
                    color: palette.accent,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Tous vos services MBONGO accessibles depuis un seul ecran.',
                  style: TextStyle(
                    color: AppColors.textSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.text,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MbongoThemeController.current.panelAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.24),
        ),
      ),
      child: const Text(
        'Aucune activite recente pour le moment.',
        style: TextStyle(
          color: AppColors.darkMuted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildFooterCard(MbongoThemePalette palette) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text(
        'Vos finances en main. MBONGO simplifie chaque operation du quotidien.',
        style: TextStyle(
          color: AppColors.textSoft,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Future<void> _showQuickMenu(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final palette = MbongoThemeController.current;
        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: palette.panel,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _menuAction(context, 'Historique', Icons.history_rounded, () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TransactionsScreen()),
                );
              }),
              _menuAction(context, 'Portefeuille', Icons.wallet_rounded, () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WalletScreen()),
                );
              }),
              _menuAction(context, 'Deconnexion', Icons.logout_rounded, () async {
                Navigator.pop(context);
                await ref.read(authProvider.notifier).logout();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _menuAction(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    final isLogout = label == 'Deconnexion';
    final accent = isLogout ? AppColors.red : MbongoThemeController.current.accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLogout
              ? const [
                  Color(0xFF3B1018),
                  Color(0xFF561722),
                ]
              : [
                  const Color(0xFF0D2145).withValues(alpha: 0.96),
                  const Color(0xFF102A55).withValues(alpha: 0.92),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accent.withValues(alpha: 0.22),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Icon(icon, color: accent),
        title: Text(
          label,
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w800,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: isLogout ? const Color(0xFFFFC7CE) : AppColors.textSoft,
        ),
      ),
    );
  }

  Color _iconColor(String title, MbongoThemePalette palette) {
    if (title.contains('Envoyer')) return palette.accent;
    if (title.contains('Demander')) return AppColors.green;
    if (title.contains('Changer')) return AppColors.gold;
    if (title.contains('International')) return AppColors.blueSoft;
    if (title.contains('Retirer')) return AppColors.orange;
    if (title.contains('cartes')) return palette.accentStrong;
    if (title.contains('Unites')) return AppColors.orange;
    if (title.contains('TV')) return AppColors.gold;
    if (title.contains('Deposer')) return AppColors.cyan;

    if (title.contains('Taux')) return AppColors.gold;
    if (title.contains('Payer')) return AppColors.green;
    return palette.accent;
  }

  Widget? _screenForService(String title) {
    if (title.contains('Envoyer')) return const SendMoneyScreen();
    if (title.contains('Demander')) return const RequestMoneyScreen();
    if (title.contains('Changer')) return const ExchangeMoneyScreen();
    if (title.contains('International')) return const TransferInternationalScreen();
    if (title.contains('Retirer')) return const WithdrawScreen();
    if (title.contains('cartes')) return const VirtualCardsScreen();
    if (title.contains('Unites')) return const BuyAirtimeScreen();
    if (title.contains('TV')) return const TvSubscriptionScreen();
    if (title.contains('Deposer')) return const ApproMbongoScreen();

    if (title.contains('Taux')) return const ExchangeRatesScreen();
    if (title.contains('Payer')) return const MerchantPaymentScreen();
    if (title.contains('Factures')) return const BillPayScreen();
    if (title.contains('Mon QR')) return const ShareProfileScreen();
    return null;
  }

  Future<void> _onServiceTap(String title) async {
    // QR scan : action directe, pas de screen widget
    if (title.contains('Scanner QR')) {
      await scanAndRoute(context);
      return;
    }
    final screen = _screenForService(title);
    if (screen == null) return;

    const infoScreens = ['Taux', 'Mon QR'];
    final needsKyc = !infoScreens.any((s) => title.contains(s));

    if (needsKyc) {
      final access = await KycGuardService.sensitiveOperationAccess();
      if (!access.allowed) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(access.message),
          backgroundColor: const Color(0xFFC44040),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        return;
      }
    }

    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

}

class _ActivityTile extends StatelessWidget {
  final Map<String, dynamic> tx;

  const _ActivityTile(this.tx);

  String _money(num value) {
    return value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]} ',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCredit = (tx['isCredit'] ?? false) == true;
    final amount = ((tx['amount'] ?? 0) as num).toDouble();
    final label = (tx['label'] ?? 'Transaction').toString();
    final currency = (tx['currency'] ?? 'CDF').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MbongoThemeController.current.panelAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: (isCredit ? AppColors.green : MbongoThemeController.current.accent)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCredit ? Icons.call_received_rounded : Icons.call_made_rounded,
              color: isCredit ? AppColors.green : MbongoThemeController.current.accent,
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
            '${isCredit ? '+' : '-'} ${currency == 'USD' ? '\$' : 'CDF'} ${_money(amount)}',
            style: TextStyle(
              color: isCredit ? AppColors.green : MbongoThemeController.current.accent,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
