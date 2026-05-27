import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../widgets/common/mbongo_sub_app_bar.dart';
import '../appro/appro_mbongo_screen.dart';

class DepositMethodScreen extends StatelessWidget {
  const DepositMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;

    return Scaffold(
      backgroundColor: palette.shellBottom,
      appBar: MbongoSubAppBar(title: 'Ajouter de l\'argent'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.shellTop, palette.shellBottom],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choisissez une méthode',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sélectionnez comment vous souhaitez recharger votre compte.',
                    style: TextStyle(
                      color: AppColors.textSoft,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Agent cash-in — ACTIF
            _MethodTile(
              icon: Icons.support_agent_rounded,
              color: AppColors.orange,
              title: 'Agent Mbongo',
              subtitle: 'Déposez de l\'argent via un agent agréé près de chez vous.',
              badge: 'Disponible',
              badgeColor: AppColors.green,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ApproMbongoScreen()),
              ),
            ),
            const SizedBox(height: 12),

            // Mobile Money — stub
            _MethodTile(
              icon: Icons.phone_android_rounded,
              color: AppColors.cyan,
              title: 'Mobile Money',
              subtitle: 'Rechargez directement depuis votre compte mobile money.',
              badge: 'Bientôt',
              badgeColor: AppColors.gold,
              onTap: () => _showComingSoon(context, 'Mobile Money'),
            ),
            const SizedBox(height: 12),

            // Virement bancaire — stub
            _MethodTile(
              icon: Icons.account_balance_rounded,
              color: AppColors.gold,
              title: 'Virement bancaire',
              subtitle: 'Transférez depuis votre compte bancaire vers Mbongo.',
              badge: 'Bientôt',
              badgeColor: AppColors.gold,
              onTap: () => _showComingSoon(context, 'Virement bancaire'),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String method) {
    final palette = MbongoThemeController.current;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: palette.panel,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.schedule_rounded, color: AppColors.gold, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                '$method — Bientôt disponible',
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Cette fonctionnalité sera disponible prochainement. En attendant, utilisez un Agent Mbongo pour recharger votre compte.',
                style: TextStyle(
                  color: AppColors.textSoft,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Compris'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final VoidCallback onTap;

  const _MethodTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    final isActive = badge == 'Disponible';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: palette.panelAlt,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isActive
                  ? color.withValues(alpha: 0.3)
                  : AppColors.border.withValues(alpha: 0.2),
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              color: badgeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSoft,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: isActive ? color : AppColors.textSoft,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
