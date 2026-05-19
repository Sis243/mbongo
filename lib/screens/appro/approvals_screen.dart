import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../widgets/common/mbongo_money_particles.dart';
import '../../widgets/common/mbongo_sub_app_bar.dart';

class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  final List<Map<String, dynamic>> approvals = [
    {
      'title': 'Appro Mbongo - Portefeuille CDF',
      'requester': 'Floribo Capo',
      'amount': 'CDF 250 000',
      'status': 'EN ATTENTE',
    },
    {
      'title': 'Validation retrait M-Pesa',
      'requester': 'Floribo Capo',
      'amount': 'CDF 120 000',
      'status': 'EN ATTENTE',
    },
    {
      'title': 'Activation carte virtuelle',
      'requester': 'Patrick Mbuyi',
      'amount': 'USD 15',
      'status': 'EN ATTENTE',
    },
  ];

  void _approve(int index) {
    setState(() {
      approvals[index]['status'] = 'APPROUVE';
    });
  }

  void _reject(int index) {
    setState(() {
      approvals[index]['status'] = 'REJETE';
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;

    return Scaffold(
      backgroundColor: palette.shellBottom,
      appBar: MbongoSubAppBar(title: 'Approbations'),
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
                color: palette.accentStrong,
                count: 19,
                opacity: 0.11,
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _header(palette),
                const SizedBox(height: 18),
                ...List.generate(approvals.length, (i) {
                  final item = approvals[i];
                  final status = item['status'].toString();
                  final isPending = status == 'EN ATTENTE';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: palette.panelAlt,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.24),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 14,
                          offset: Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: palette.accent.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.verified_user_rounded,
                                color: palette.accent,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title'].toString(),
                                    style: const TextStyle(
                                      color: AppColors.darkText,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['requester'].toString(),
                                    style: const TextStyle(
                                      color: AppColors.darkMuted,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Montant',
                                style: TextStyle(
                                  color: AppColors.darkMuted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              item['amount'].toString(),
                              style: const TextStyle(
                                color: AppColors.darkText,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Statut',
                                style: TextStyle(
                                  color: AppColors.darkMuted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              status,
                              style: TextStyle(
                                color: status == 'APPROUVE'
                                    ? AppColors.green
                                    : status == 'REJETE'
                                        ? AppColors.red
                                        : palette.accentStrong,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        if (isPending) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _reject(i),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.red,
                                    side: const BorderSide(color: AppColors.red),
                                  ),
                                  child: const Text('Rejeter'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _approve(i),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Approuver'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(MbongoThemePalette palette) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette.bannerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.24),
        ),
        boxShadow: [
          BoxShadow(
            color: palette.glow.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_rounded, color: palette.accentStrong),
              const SizedBox(width: 8),
              const Text(
                "Centre d'approbation",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Demandes en attente',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Validez ou rejetez les operations soumises dans votre espace MBONGO.',
            style: TextStyle(
              color: Color(0xFFE8EEF8),
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
