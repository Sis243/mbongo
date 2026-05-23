import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
import '../core/theme/mbongo_theme.dart';
import '../widgets/common/mbongo_money_particles.dart';
import 'accounts/accounts_screen.dart';
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
  bool _merchantMode = false;
  bool _hasMerchantAccounts = false;
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

  List<Widget> get pages => _merchantMode ? _merchantPages : _userPages;
  List<String> get labels => _merchantMode ? _merchantLabels : _userLabels;
  List<IconData> get icons => _merchantMode ? _merchantIcons : _userIcons;

  @override
  void initState() {
    super.initState();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final offline = results.every((r) => r == ConnectivityResult.none);
      if (mounted && offline != _isOffline) setState(() => _isOffline = offline);
    });
    _checkMerchantAccounts();
  }

  Future<void> _checkMerchantAccounts() async {
    try {
      final list = await ApiService.getMerchantAccounts();
      if (list.isNotEmpty && mounted) {
        setState(() => _hasMerchantAccounts = true);
      }
    } catch (_) {}
  }

  void _toggleMerchantMode() {
    setState(() {
      _merchantMode = !_merchantMode;
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
      floatingActionButton: _hasMerchantAccounts
          ? FloatingActionButton.small(
              heroTag: 'merchant_toggle',
              backgroundColor: _merchantMode ? AppColors.green : palette.accent,
              onPressed: _toggleMerchantMode,
              tooltip: _merchantMode ? 'Mode client' : 'Mode marchand',
              child: Icon(
                _merchantMode ? Icons.person_rounded : Icons.point_of_sale_rounded,
                color: Colors.white,
                size: 20,
              ),
            )
          : null,
      body: Stack(
        children: [
          const _ShellBackdrop(),
          SafeArea(
            child: Column(
              children: [
                if (_merchantMode)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    color: AppColors.green.withValues(alpha: 0.15),
                    child: Row(
                      children: [
                        const Icon(Icons.store_rounded, color: AppColors.green, size: 15),
                        const SizedBox(width: 6),
                        const Text(
                          'Mode Marchand actif',
                          style: TextStyle(
                            color: AppColors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _toggleMerchantMode,
                          child: const Text(
                            'Quitter',
                            style: TextStyle(
                              color: AppColors.green,
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
                      key: ValueKey('$_merchantMode-$currentIndex'),
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
