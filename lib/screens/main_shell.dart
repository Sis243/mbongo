import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../providers/pending_tab_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/presentation/auth_notifier.dart';
import '../core/theme/app_colors.dart';
import '../features/notifications/presentation/notifications_provider.dart';
import '../services/api_service.dart';
import '../core/theme/mbongo_theme.dart';
import '../widgets/common/inactivity_lock_wrapper.dart';
import '../widgets/common/mbongo_money_particles.dart';
import 'accounts/accounts_screen.dart';
import 'agent/agent_shell.dart';
import 'home_screen.dart';
import 'merchant/merchant_shell.dart';
import 'profile_screen.dart';
import 'wallet/wallet_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int currentIndex = 0;
  bool _isOffline = false;
  bool _showReconnected = false;
  Timer? _reconnectedTimer;
  // 0 = user, 1 = merchant, 2 = agent
  int _roleMode = 0;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  StreamSubscription<int>? _notificationNavSub;
  StreamSubscription<void>? _sessionExpiredSub;

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

  List<Widget> get pages => _userPages;
  List<String> get labels => _userLabels;
  List<IconData> get icons => _userIcons;

  @override
  void initState() {
    super.initState();
    _notificationNavSub = NotificationNavigation.stream.listen((tab) {
      if (mounted) setState(() => currentIndex = tab);
    });
    _sessionExpiredSub = ApiService.sessionExpiredStream.listen((_) => _onSessionExpired());
    _checkDeviceSecurity();
    // Delay initial check: some devices briefly report ConnectivityResult.none
    // at startup before the network stack is fully initialized.
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      Connectivity().checkConnectivity().then((results) {
        if (!mounted) return;
        final offline = results.isNotEmpty &&
            results.every((r) => r == ConnectivityResult.none);
        if (offline) {
          // Double-check after another second to avoid false positives
          Future.delayed(const Duration(seconds: 1), () {
            if (!mounted) return;
            Connectivity().checkConnectivity().then((r2) {
              if (!mounted) return;
              final stillOffline = r2.isNotEmpty &&
                  r2.every((r) => r == ConnectivityResult.none);
              setState(() => _isOffline = stillOffline);
            });
          });
        } else {
          setState(() => _isOffline = false);
        }
      });
    });
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final offline = results.isNotEmpty &&
          results.every((r) => r == ConnectivityResult.none);
      if (!mounted || offline == _isOffline) return;
      if (!offline && _isOffline) {
        setState(() { _isOffline = false; _showReconnected = true; });
        _reconnectedTimer?.cancel();
        _reconnectedTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _showReconnected = false);
        });
      } else {
        setState(() => _isOffline = offline);
      }
    });
    _checkRoles();
  }

  Future<void> _checkRoles() async {
    try {
      final log = await ApiService.getAgentProfitLog()
          .timeout(const Duration(seconds: 3));
      final agentCode = log['agentCode']?.toString() ?? log['data']?['agentCode']?.toString();
      if (agentCode != null && agentCode.isNotEmpty && mounted) {
        setState(() => _roleMode = 2);
        return;
      }
    } catch (_) {}
    try {
      final me = await ApiService.getMyMerchantProfile()
          .timeout(const Duration(seconds: 3));
      final isMerchant = me['isMerchant'] == true || me['data']?['isMerchant'] == true;
      if (isMerchant && mounted) {
        setState(() => _roleMode = 1);
        return;
      }
    } catch (_) {}
  }

  static const _securityChannel = MethodChannel('com.mbongo.app/security');

  Future<void> _checkDeviceSecurity() async {
    try {
      final isRooted = await _securityChannel.invokeMethod<bool>('isRooted') ?? false;
      if (!isRooted || !mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100)),
              SizedBox(width: 10),
              Text('Appareil non sécurisé'),
            ],
          ),
          content: const Text(
            'Votre appareil semble être rooté ou modifié.\n\n'
            'Utiliser MBONGO sur un appareil rooté expose vos données financières à des risques de sécurité importants.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continuer quand même'),
            ),
          ],
        ),
      );
    } catch (_) {}
  }

  Future<void> _onSessionExpired() async {
    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session expirée. Veuillez vous reconnecter.'),
        backgroundColor: Color(0xFFB00020),
        duration: Duration(seconds: 4),
      ),
    );
    context.go('/auth/login');
  }

  @override
  void dispose() {
    _reconnectedTimer?.cancel();
    _sessionExpiredSub?.cancel();
    _notificationNavSub?.cancel();
    _connectivitySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget shell;
    if (_roleMode == 1) {
      shell = const MerchantShell();
    } else if (_roleMode == 2) {
      shell = const AgentShell();
    } else {
      shell = _buildClientShell(context);
    }
    return InactivityLockWrapper(child: shell);
  }

  Widget _buildClientShell(BuildContext context) {
    final palette = MbongoThemeController.current;
    final darkMode = MbongoThemeController.darkModeEnabled.value;
    final activeText = darkMode ? AppColors.text : AppColors.darkText;
    final inactiveText = darkMode ? AppColors.muted : AppColors.darkMuted;
    final unreadAsync = ref.watch(unreadCountProvider);
    final unreadCount = unreadAsync.valueOrNull ?? 0;
    return Scaffold(
      backgroundColor: palette.shellBottom,
      floatingActionButton: null,
      body: Stack(
        children: [
          const _ShellBackdrop(),
          SafeArea(
            child: Column(
              children: [
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
          if (_isOffline || _showReconnected)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  color: _isOffline
                      ? AppColors.red.withValues(alpha: 0.92)
                      : const Color(0xFF1B8C4E).withValues(alpha: 0.93),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        _isOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isOffline
                            ? 'Hors ligne — vérifiez votre connexion'
                            : 'Connexion rétablie',
                        style: const TextStyle(
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
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                icons[index],
                                size: 22,
                                color: selected ? palette.accent : inactiveText,
                              ),
                              if (index == labels.length - 1 && unreadCount > 0)
                                Positioned(
                                  top: -4,
                                  right: -6,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: AppColors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: palette.panel, width: 1.5),
                                    ),
                                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                    child: Text(
                                      unreadCount > 9 ? '9+' : '$unreadCount',
                                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
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

