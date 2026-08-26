import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../features/auth/presentation/auth_notifier.dart';
import '../../screens/airtime/buy_airtime_screen.dart';
import '../../screens/appro/appro_mbongo_screen.dart';
import '../../screens/exchange/exchange_money_screen.dart';
import '../../screens/profile/security_screen.dart';
import '../../screens/transactions_screen.dart';
import '../../screens/transfer/send_money_screen.dart';
import '../../screens/transfer/transfer_international_screen.dart';
import '../../screens/tv/tv_subscription_screen.dart';
import 'agent_cashin_screen.dart';
import 'agent_dashboard_screen.dart';
import 'agent_payouts_screen.dart';

class AgentShell extends ConsumerStatefulWidget {
  const AgentShell({super.key});

  @override
  ConsumerState<AgentShell> createState() => _AgentShellState();
}

class _AgentShellState extends ConsumerState<AgentShell> {
  int _index = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _pages = [
    AgentDashboardScreen(),
    AgentCashInScreen(),
    AgentCashOutScreen(),
    TransactionsScreen(),
  ];

  static const _labels = ['Dashboard', 'Cash-In', 'Cash-Out', 'Transactions'];
  static const _icons = [
    Icons.support_agent_rounded,
    Icons.arrow_downward_rounded,
    Icons.arrow_upward_rounded,
    Icons.receipt_long_rounded,
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
      drawer: _AgentDrawer(
        onClose: () => _scaffoldKey.currentState?.closeDrawer(),
        onNavigate: (page) {
          _scaffoldKey.currentState?.closeDrawer();
          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        },
        onTab: (i) {
          _scaffoldKey.currentState?.closeDrawer();
          setState(() => _index = i);
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
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _scaffoldKey.currentState?.openDrawer(),
                        child: Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.orange.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(Icons.menu_rounded, color: AppColors.orange, size: 20),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.orange.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.support_agent_rounded, color: AppColors.orange, size: 13),
                            SizedBox(width: 5),
                            Text('Mode Agent',
                                style: TextStyle(color: AppColors.orange, fontSize: 11.5, fontWeight: FontWeight.w800)),
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
                          color: selected ? AppColors.orange.withValues(alpha: 0.28) : Colors.transparent,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_icons[i], size: 22,
                              color: selected ? AppColors.orange : inactiveText),
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

class _AgentDrawer extends ConsumerWidget {
  final VoidCallback onClose;
  final void Function(Widget) onNavigate;
  final void Function(int) onTab;

  const _AgentDrawer({
    required this.onClose,
    required this.onNavigate,
    required this.onTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = MbongoThemeController.current;

    return Drawer(
      backgroundColor: palette.panel,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A0A00), Color(0xFF3D1A00)],
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
                      Text('Mbongo Agent',
                          style: TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w900)),
                      Text('Interface agent',
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
                  _item(context, Icons.dashboard_rounded, 'Tableau de bord', AppColors.cyan,
                      () => onTab(0)),
                  _item(context, Icons.arrow_downward_rounded, 'Cash-In (recevoir)', AppColors.green,
                      () => onTab(1)),
                  _item(context, Icons.arrow_upward_rounded, 'Cash-Out (retirer)', AppColors.orange,
                      () => onTab(2)),
                  _item(context, Icons.receipt_long_rounded, 'Transactions', AppColors.text,
                      () => onTab(3)),
                  _item(context, Icons.payments_rounded, 'Commissions & Versements', AppColors.green,
                      () => onNavigate(const AgentPayoutsScreen())),
                  const Divider(height: 24, indent: 16, endIndent: 16, color: AppColors.border),
                  _item(context, Icons.send_rounded, 'Envoyer de l\'argent', AppColors.green,
                      () => onNavigate(const SendMoneyScreen())),
                  _item(context, Icons.add_card_rounded, 'Ajouter de l\'argent', AppColors.cyan,
                      () => onNavigate(const ApproMbongoScreen())),
                  _item(context, Icons.currency_exchange_rounded, 'Change de devises', AppColors.gold,
                      () => onNavigate(const ExchangeMoneyScreen())),
                  _item(context, Icons.swap_horiz_rounded, 'Transfert international', AppColors.gold,
                      () => onNavigate(const TransferInternationalScreen())),
                  _item(context, Icons.receipt_rounded, 'Paiement de factures', AppColors.gold,
                      () => onNavigate(const TvSubscriptionScreen())),
                  _item(context, Icons.phone_android_rounded, 'Recharge mobile', AppColors.green,
                      () => onNavigate(const BuyAirtimeScreen())),
                  const Divider(height: 24, indent: 16, endIndent: 16, color: AppColors.border),
                  _item(context, Icons.security_rounded, 'Sécurité 2FA', AppColors.gold,
                      () => onNavigate(const SecurityScreen())),
                  _item(context, Icons.help_outline_rounded, 'Centre d\'aide', AppColors.textSoft,
                      () => onNavigate(const _HelpScreen())),
                ],
              ),
            ),
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

  Widget _item(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
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

class _HelpScreen extends StatelessWidget {
  const _HelpScreen();

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    return Scaffold(
      backgroundColor: palette.shellBottom,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Centre d\'aide', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800)),
        iconTheme: const IconThemeData(color: AppColors.text),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A0A00), Color(0xFF3D1A00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.help_outline_rounded, color: AppColors.orange, size: 28),
                    SizedBox(width: 10),
                    Text('Comment pouvons-nous vous aider ?',
                        style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w900)),
                  ],
                ),
                SizedBox(height: 10),
                Text('Trouvez des réponses à vos questions sur l\'application agent Mbongo.',
                    style: TextStyle(color: AppColors.textSoft, fontSize: 13, height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...[
            ('Comment effectuer un Cash-In ?', 'Entrez le numéro de téléphone du client, saisissez le montant et confirmez la transaction.'),
            ('Comment effectuer un Cash-Out ?', 'Entrez le numéro de téléphone du client, saisissez le montant à retirer et confirmez.'),
            ('Quels sont mes frais de commission ?', 'Vos commissions sont visibles dans le Journal des profits. Elles sont calculées automatiquement.'),
            ('Comment voir mes transactions ?', 'Allez dans l\'onglet Transactions du menu principal.'),
            ('Comment activer la 2FA ?', 'Allez dans Sécurité 2FA depuis le menu latéral.'),
          ].map((faq) => _FaqCard(question: faq.$1, answer: faq.$2)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.panelAlt,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
            ),
            child: const Column(
              children: [
                Icon(Icons.support_agent_rounded, color: AppColors.orange, size: 36),
                SizedBox(height: 10),
                Text('Obtenez de l\'aide',
                    style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w900)),
                SizedBox(height: 6),
                Text('Contactez notre équipe de support disponible 24h/24.',
                    style: TextStyle(color: AppColors.textSoft, fontSize: 13),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqCard extends StatefulWidget {
  final String question;
  final String answer;
  const _FaqCard({required this.question, required this.answer});

  @override
  State<_FaqCard> createState() => _FaqCardState();
}

class _FaqCardState extends State<_FaqCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.question,
                        style: const TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                  Icon(_open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: AppColors.orange, size: 20),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Text(widget.answer,
                  style: const TextStyle(color: AppColors.textSoft, fontSize: 12, height: 1.5)),
            ),
        ],
      ),
    );
  }
}
