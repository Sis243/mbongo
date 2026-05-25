import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../features/auth/presentation/auth_notifier.dart';
import '../../screens/exchange/exchange_money_screen.dart';
import '../../screens/payment_links/payment_links_screen.dart';
import '../../screens/profile/security_screen.dart';
import '../../screens/profile/support_screen.dart';
import '../../screens/transactions_screen.dart';
import '../../screens/withdraw/withdraw_screen.dart';
import 'merchant_api_key_screen.dart';
import 'merchant_dashboard_screen.dart';
import 'merchant_gateway_screen.dart';
import 'merchant_payment_screen.dart';

class MerchantShell extends ConsumerStatefulWidget {
  const MerchantShell({super.key});

  @override
  ConsumerState<MerchantShell> createState() => _MerchantShellState();
}

class _MerchantShellState extends ConsumerState<MerchantShell> {
  int _index = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _pages = [
    MerchantDashboardScreen(),
    MerchantPaymentScreen(),
    TransactionsScreen(),
    PaymentLinksScreen(),
  ];

  static const _labels = ['Tableau de bord', 'POS', 'Transactions', 'Liens'];
  static const _icons = [
    Icons.dashboard_rounded,
    Icons.point_of_sale_rounded,
    Icons.receipt_long_rounded,
    Icons.link_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    final darkMode = MbongoThemeController.darkModeEnabled.value;
    final activeText = darkMode ? AppColors.text : AppColors.darkText;
    final inactiveText = darkMode ? AppColors.muted : AppColors.darkMuted;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: palette.shellBottom,
      drawer: _MerchantDrawer(
        onClose: () => _scaffoldKey.currentState?.closeDrawer(),
        onNavigate: (page) {
          _scaffoldKey.currentState?.closeDrawer();
          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        },
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [palette.shellTop, palette.shellBottom],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Merchant top bar
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _scaffoldKey.currentState?.openDrawer(),
                        child: Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(Icons.menu_rounded, color: AppColors.green, size: 20),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.store_rounded, color: AppColors.green, size: 13),
                            SizedBox(width: 5),
                            Text('Mode Marchand',
                                style: TextStyle(color: AppColors.green, fontSize: 11.5, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: KeyedSubtree(
                      key: ValueKey(_index),
                      child: _pages[_index],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: palette.panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
          ),
          child: Row(
            children: List.generate(_labels.length, (i) {
              final selected = _index == i;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == _labels.length - 1 ? 0 : 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() => _index = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected ? AppColors.green.withValues(alpha: 0.28) : Colors.transparent,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_icons[i], size: 22,
                              color: selected ? AppColors.green : inactiveText),
                          const SizedBox(height: 5),
                          Text(_labels[i],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: selected ? activeText : inactiveText,
                                fontSize: 10.5,
                                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _MerchantDrawer extends ConsumerWidget {
  final VoidCallback onClose;
  final void Function(Widget) onNavigate;

  const _MerchantDrawer({
    required this.onClose,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = MbongoThemeController.current;

    return Drawer(
      backgroundColor: palette.panel,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0E2346), Color(0xFF14305D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.3))),
              ),
              child: Row(
                children: [
                  Image.asset('assets/images/mbongo_logo.png', width: 44, height: 44),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mbongo Marchand',
                          style: TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w900)),
                      Text('Interface marchande',
                          style: TextStyle(color: AppColors.textSoft, fontSize: 12)),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(onTap: onClose, child: const Icon(Icons.close_rounded, color: AppColors.textSoft, size: 20)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _drawerItem(context, Icons.dashboard_rounded, 'Tableau de bord', AppColors.cyan,
                      () => onClose()),
                  _drawerItem(context, Icons.qr_code_rounded, 'Recevoir de l\'argent', AppColors.green,
                      () => onNavigate(const MerchantDashboardScreen())),
                  _drawerItem(context, Icons.currency_exchange_rounded, 'Change de devises', AppColors.gold,
                      () => onNavigate(const ExchangeMoneyScreen())),
                  _drawerItem(context, Icons.link_rounded, 'Lien de paiement', AppColors.cyan,
                      () => onNavigate(const PaymentLinksScreen())),
                  _drawerItem(context, Icons.arrow_upward_rounded, 'Retirer', AppColors.orange,
                      () => onNavigate(const WithdrawScreen())),
                  _drawerItem(context, Icons.receipt_long_rounded, 'Transactions', AppColors.text,
                      () => onNavigate(const TransactionsScreen())),
                  const Divider(height: 24, indent: 16, endIndent: 16, color: AppColors.border),
                  _drawerItem(context, Icons.security_rounded, 'Sécurité 2FA', AppColors.gold,
                      () => onNavigate(const SecurityScreen())),
                  _drawerItem(context, Icons.vpn_key_rounded, 'Clé API', AppColors.cyan,
                      () => onNavigate(const MerchantApiKeyScreen())),
                  _drawerItem(context, Icons.payment_rounded, 'Paramètres passerelle', AppColors.green,
                      () => onNavigate(const MerchantGatewayScreen())),
                  _drawerItem(context, Icons.integration_instructions_rounded, 'Intégrer la passerelle', AppColors.orange,
                      () => onNavigate(const MerchantGatewayScreen())),
                  _drawerItem(context, Icons.api_rounded, 'API développeur', AppColors.gold,
                      () => onNavigate(const MerchantApiKeyScreen())),
                  const Divider(height: 24, indent: 16, endIndent: 16, color: AppColors.border),
                  _drawerItem(context, Icons.support_agent_rounded, 'Soutien', AppColors.textSoft,
                      () => onNavigate(const SupportScreen())),
                ],
              ),
            ),
            // Logout
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) context.go('/auth/login');
                      },
                      icon: const Icon(Icons.logout_rounded, size: 16),
                      label: const Text('Déconnexion'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.red,
                        side: const BorderSide(color: AppColors.red),
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

  Widget _drawerItem(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(label,
          style: const TextStyle(color: AppColors.text, fontSize: 13.5, fontWeight: FontWeight.w700)),
      onTap: onTap,
      dense: true,
      horizontalTitleGap: 10,
    );
  }
}
