import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/mbongo_theme.dart';
import '../widgets/common/mbongo_money_particles.dart';
import 'home_screen.dart';
import 'accounts/accounts_screen.dart';
import 'wallet/wallet_screen.dart';
import 'profile_screen.dart';

class HomeShell extends StatefulWidget {
  final Map<String, dynamic> userData;

  const HomeShell({super.key, required this.userData});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    final pages = [
      const HomeScreen(),
      const AccountsScreen(),
      const WalletScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: palette.shellBottom,
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
                count: 16,
                opacity: 0.09,
              ),
            ),
          ),
          pages[index],
        ],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: palette.panel,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: palette.glow.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BottomItem(
              icon: Icons.home_filled,
              label: "Accueil",
              active: index == 0,
              color: palette.accentStrong,
              onTap: () => setState(() => index = 0),
            ),
            _BottomItem(
              icon: Icons.credit_card_rounded,
              label: "Comptes",
              active: index == 1,
              color: palette.accent,
              onTap: () => setState(() => index = 1),
            ),
            _CenterScanItem(
              onTap: () {
                setState(() => index = 0);
              },
            ),
            _BottomItem(
              icon: Icons.account_balance_wallet_rounded,
              label: "Portemonnaie",
              active: index == 2,
              color: AppColors.green,
              onTap: () => setState(() => index = 2),
            ),
            _BottomItem(
              icon: Icons.person_outline_rounded,
              label: "Profil",
              active: index == 3,
              color: palette.accentStrong,
              onTap: () => setState(() => index = 3),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _BottomItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = active ? color : color.withValues(alpha: 0.42);
    final darkMode = MbongoThemeController.darkModeEnabled.value;
    final textColor = active
        ? (darkMode ? AppColors.text : AppColors.darkText)
        : (darkMode ? AppColors.text.withValues(alpha: 0.38) : AppColors.darkMuted);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: active ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterScanItem extends StatelessWidget {
  final VoidCallback onTap;

  const _CenterScanItem({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 66,
        height: 66,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: palette.bannerGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: palette.glow.withValues(alpha: 0.24),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(
          Icons.qr_code_scanner_rounded,
          color: Colors.white,
          size: 34,
        ),
      ),
    );
  }
}
