import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
import '../core/theme/mbongo_theme.dart';
import '../widgets/common/mbongo_money_particles.dart';
import 'accounts/accounts_screen.dart';
import 'agent/agent_cashin_screen.dart';
import 'agent/agent_dashboard_screen.dart';
import 'home_screen.dart';
import 'merchant/merchant_payment_screen.dart';
import 'payment_links/payment_links_screen.dart';
import 'profile_screen.dart';
import 'transactions_screen.dart';
import 'wallet/wallet_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int currentIndex = 0;
  bool _isOffline = false;
  // 0 = user, 1 = merchant, 2 = agent
  int _roleMode = 0;
  bool _hasMerchantAccounts = false;
  bool _isAgent = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  // User mode
  static const _userPages = [
    HomeScreen(),
    AccountsScreen(),
    WalletScreen(),
    ProfileScreen(),
  ];
  static const _userLabels = ['Accueil', 'Comptes', 'Wallet', 'Profil'];
  static const _userIcons = [
    Icons.space_dashboard_rounded,
    Icons.account_balance_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.person_rounded,
  ];

  // Merchant mode
  static const _merchantPages = [
    MerchantPaymentScreen(),
    TransactionsScreen(),
    PaymentLinksScreen(),
    ProfileScreen(),
  ];
  static const _merchantLabels = ['Encaisser', 'Ventes', 'Liens', 'Profil'];
  static const _merchantIcons = [
    Icons.point_of_sale_rounded,
    Icons.receipt_long_rounded,
    Icons.link_rounded,
    Icons.person_rounded,
  ];

  // Agent mode
  static const _agentPages = [
    AgentDashboardScreen(),
    AgentCashInScreen(),
    AgentCashOutScreen(),
    ProfileScreen(),
  ];
  static const _agentLabels = ['Dashboard', 'Cash-In', 'Cash-Out', 'Profil'];
  static const _agentIcons = [
    Icons.support_agent_rounded,
    Icons.arrow_downward_rounded,
    Icons.arrow_upward_rounded,
    Icons.person_rounded,
  ];

  List<Widget> get pages {
    if (_roleMode == 1) return _merchantPages;
    if (_roleMode == 2) return _agentPages;
    return _userPages;
  }
  List<String> get labels {
    if (_roleMode == 1) return _merchantLabels;
    if (_roleMode == 2) return _agentLabels;
    return _userLabels;
  }
  List<IconData> get icons {
    if (_roleMode == 1) return _merchantIcons;
    if (_roleMode == 2) return _agentIcons;
    return _userIcons;
  }

  @override
  void initState() {
    super.initState();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final offline = results.every((r) => r == ConnectivityResult.none);
      if (mounted && offline != _isOffline) setState(() => _isOffline = offline);
    });
    _checkRoles();
  }

  Future<void> _checkRoles() async {
    try {
      final list = await ApiService.getMerchantAccounts();
      if (list.isNotEmpty && mounted) setState(() => _hasMerchantAccounts = true);
    } catch (_) {}
    try {
      final agents = await ApiService.getCashAgents();
      if (agents.isNotEmpty && mounted) setState(() => _isAgent = true);
    } catch (_) {}
  }

  void _toggleMerchantMode() {
    setState(() {
      _roleMode = _roleMode == 1 ? 0 : 1;
      currentIndex = 0;
    });
  }

  void _toggleAgentMode() {
    setState(() {
      _roleMode = _roleMode == 2 ? 0 : 2;
      currentIndex = 0;
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    final darkMode = MbongoThemeController.darkModeEnabled.value;
    final activeText = darkMode ? AppColors.text : AppColors.darkText;
    final inactiveText = darkMode ? AppColors.muted : AppColors.darkMuted;
    return Scaffold(
      backgroundColor: palette.shellBottom,
      floatingActionButton: (_hasMerchantAccounts || _isAgent)
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_hasMerchantAccounts)
                  FloatingActionButton.small(
                    heroTag: 'merchant_toggle',
                    backgroundColor: _roleMode == 1 ? AppColors.green : palette.accent,
                    onPressed: _toggleMerchantMode,
                    tooltip: _roleMode == 1 ? 'Mode client' : 'Mode marchand',
                    child: Icon(
                      _roleMode == 1 ? Icons.person_rounded : Icons.point_of_sale_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                if (_hasMerchantAccounts && _isAgent) const SizedBox(height: 8),
                if (_isAgent)
                  FloatingActionButton.small(
                    heroTag: 'agent_toggle',
                    backgroundColor: _roleMode == 2 ? AppColors.orange : palette.accent,
                    onPressed: _toggleAgentMode,
                    tooltip: _roleMode == 2 ? 'Mode client' : 'Mode agent',
                    child: Icon(
                      _roleMode == 2 ? Icons.person_rounded : Icons.support_agent_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
              ],
            )
          : null,
      body: Stack(
        children: [
          const _ShellBackdrop(),
          SafeArea(
            child: Column(
              children: [
                if (_roleMode != 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    color: (_roleMode == 1 ? AppColors.green : AppColors.orange)
                        .withValues(alpha: 0.15),
                    child: Row(
                      children: [
                        Icon(
                          _roleMode == 1 ? Icons.store_rounded : Icons.support_agent_rounded,
                          color: _roleMode == 1 ? AppColors.green : AppColors.orange,
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _roleMode == 1 ? 'Mode Marchand actif' : 'Mode Agent actif',
                          style: TextStyle(
                            color: _roleMode == 1 ? AppColors.green : AppColors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() { _roleMode = 0; currentIndex = 0; }),
                          child: Text(
                            'Quitter',
                            style: TextStyle(
                              color: _roleMode == 1 ? AppColors.green : AppColors.orange,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: KeyedSubtree(
                      key: ValueKey('$_roleMode-$currentIndex'),
                      child: pages[currentIndex],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isOffline)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  color: AppColors.red.withValues(alpha: 0.92),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Row(
                    children: [
                      Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Hors ligne — verifiez votre connexion',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
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
            color: MbongoThemeController.current.panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
          ),
          child: Row(
            children: List.generate(labels.length, (index) {
              final selected = currentIndex == index;
              return Expanded(
                  child: Padding(
                  padding: EdgeInsets.only(
                    right: index == labels.length - 1 ? 0 : 6,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() => currentIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? palette.accent.withValues(alpha: 0.28)
                              : Colors.transparent,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icons[index],
                            size: 22,
                            color: selected ? palette.accent : inactiveText,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            labels[index],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: selected ? activeText : inactiveText,
                              fontSize: 11.5,
                              fontWeight:
                                  selected ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
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

class _ShellBackdrop extends StatelessWidget {
  const _ShellBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                MbongoThemeController.current.shellTop,
                MbongoThemeController.current.shellBottom,
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.topLeft,
          child: Container(
            height: 220,
            width: 220,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  MbongoThemeController.current.glow.withValues(alpha: 0.38),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: Container(
            height: 240,
            width: 240,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppColors.gold.withValues(alpha: 0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        IgnorePointer(
          child: Opacity(
            opacity: 0.85,
            child: MbongoMoneyParticles(
              color: MbongoThemeController.current.accent,
              count: 22,
              opacity: 0.12,
              height: 0,
            ),
          ),
        ),
      ],
    );
  }
}
