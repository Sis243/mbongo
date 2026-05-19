import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../services/api_service.dart';
import '../../services/local_bank_service.dart';
import '../../widgets/cards/virtual_bank_card.dart';
import '../../widgets/common/mbongo_money_particles.dart';
import '../../widgets/common/mbongo_sub_app_bar.dart';

class VirtualCardDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> card;

  const VirtualCardDetailsScreen({
    super.key,
    required this.card,
  });

  @override
  State<VirtualCardDetailsScreen> createState() => _VirtualCardDetailsScreenState();
}

class _VirtualCardDetailsScreenState extends State<VirtualCardDetailsScreen> {
  bool showSensitive = false;
  bool isToggling = false;

  Future<void> _toggleStatus(bool active) async {
    setState(() => isToggling = true);
    try {
      await LocalBankService.toggleVirtualCardStatus(widget.card['id'].toString());
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => isToggling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
      return;
    }

    if (!mounted) return;
    setState(() => isToggling = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          active ? 'Carte bloquee.' : 'Carte reactivee.',
        ),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final status = (card['status'] ?? 'ACTIVE').toString();
    final active = status == 'ACTIVE';
    final currency = (card['currency'] ?? 'USD').toString();
    final palette = MbongoThemeController.current;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: MbongoSubAppBar(title: 'Details carte'),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: MbongoMoneyParticles(
                color: palette.accent,
                count: 18,
                opacity: 0.1,
                height: 0,
              ),
            ),
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
            children: [
              VirtualBankCard(
                brand: (card['brand'] ?? 'VISA').toString(),
                holderName: card['holderName'].toString(),
                maskedPan: showSensitive
                    ? (card['pan'] ?? card['maskedPan']).toString()
                    : card['maskedPan'].toString(),
                currency: currency,
                status: status,
                expiry: (card['expiry'] ?? '').toString(),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: palette.panelAlt,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.24),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 12,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _row('Porteur', card['holderName'].toString()),
                    const SizedBox(height: 12),
                    _row(
                      'Numero',
                      showSensitive
                          ? card['pan'].toString()
                          : card['maskedPan'].toString(),
                    ),
                    const SizedBox(height: 12),
                    _row('CVV', showSensitive ? card['cvv'].toString() : '***'),
                    const SizedBox(height: 12),
                    _row('Expiration', card['expiry'].toString()),
                    const SizedBox(height: 12),
                    _row('Solde', '${card["currency"]} ${card["balance"]}'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: palette.panel,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _signal(
                        'Securite',
                        showSensitive ? 'Visible' : 'Masquee',
                        palette.accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _signal(
                        'Etat',
                        active ? 'Active' : 'Bloquee',
                        active ? AppColors.green : AppColors.red,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() => showSensitive = !showSensitive);
                      },
                      icon: Icon(
                        showSensitive
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      label: Text(showSensitive ? 'Masquer' : 'Afficher'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isToggling ? null : () => _toggleStatus(active),
                      icon: Icon(
                        active ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                      ),
                      label: Text(
                        isToggling ? 'Traitement...' : active ? 'Bloquer' : 'Activer',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: active ? AppColors.red : AppColors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.darkMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.darkText,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _signal(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MbongoThemeController.current.panelAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.darkMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
