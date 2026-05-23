import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../widgets/common/mbongo_money_particles.dart';
import '../../widgets/common/mbongo_sub_app_bar.dart';

class SendMoneySuccessScreen extends StatelessWidget {
  final String phone;
  final String name;
  final double amount;
  final String currency;
  final String reason;

  const SendMoneySuccessScreen({
    super.key,
    required this.phone,
    required this.name,
    required this.amount,
    required this.currency,
    required this.reason,
  });

  String _formatAmount(double value) {
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;

    return Scaffold(
      backgroundColor: palette.shellBottom,
      appBar: MbongoSubAppBar(title: 'Confirmation'),
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
                count: 20,
                opacity: 0.11,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: palette.bannerGradient,
                      ),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: palette.glow.withValues(alpha: 0.20),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        children: [
                          Container(
                            width: 82,
                            height: 82,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.12),
                              border: Border.all(
                                color: AppColors.gold,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: AppColors.gold,
                              size: 52,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Transaction reussie',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$currency ${_formatAmount(amount)}',
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Le transfert a bien ete enregistre.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFE7EFF9),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: palette.panelAlt,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Column(
                      children: [
                        _detailRow('Montant', '$currency ${_formatAmount(amount)}'),
                        const Divider(height: 24),
                        _detailRow('Beneficiaire', name.isEmpty ? '-' : name),
                        const Divider(height: 24),
                        _detailRow('Telephone', phone.isEmpty ? '-' : phone),
                        const Divider(height: 24),
                        _detailRow('Motif', reason.isEmpty ? '-' : reason),
                        const Divider(height: 24),
                        _detailRow(
                          'Statut',
                          'Valide',
                          valueColor: palette.accentStrong,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: palette.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: palette.accent.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.security,
                          color: palette.accentStrong,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Operation traitee dans un environnement securise.',
                            style: TextStyle(
                              color: AppColors.darkText,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Share.share(
                          'MBONGO — Transfert reussi\n'
                          'Montant : $currency ${_formatAmount(amount)}\n'
                          'Beneficiaire : ${name.isEmpty ? phone : name}\n'
                          'Telephone : $phone\n'
                          'Motif : ${reason.isEmpty ? "-" : reason}\n'
                          '---\nOperation securisee via MBONGO.',
                        );
                      },
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Partager le recu'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.accentStrong,
                      ),
                      child: const Text('Terminer'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.darkMuted,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor ?? AppColors.darkText,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
