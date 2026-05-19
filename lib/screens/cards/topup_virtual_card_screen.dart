import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../services/api_service.dart';
import '../../services/local_bank_service.dart';
import '../../widgets/cards/virtual_bank_card.dart';
import '../../widgets/common/mbongo_money_particles.dart';
import '../../widgets/common/mbongo_sub_app_bar.dart';

class TopupVirtualCardScreen extends StatefulWidget {
  final Map<String, dynamic> card;

  const TopupVirtualCardScreen({
    super.key,
    required this.card,
  });

  @override
  State<TopupVirtualCardScreen> createState() => _TopupVirtualCardScreenState();
}

class _TopupVirtualCardScreenState extends State<TopupVirtualCardScreen> {
  final amountController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount =
        double.tryParse(amountController.text.trim().replaceAll(',', '.'));

    if (amount == null || amount <= 0) {
      _toast('Veuillez entrer un montant valide.');
      return;
    }

    setState(() => isLoading = true);
    bool ok;
    try {
      ok = await LocalBankService.topupVirtualCard(
        cardId: widget.card['id'].toString(),
        amount: amount,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _toast(error.message);
      return;
    }

    if (!ok) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _toast('Rechargement impossible.');
      return;
    }

    if (!mounted) return;
    setState(() => isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Carte rechargee avec succes.')),
    );
    Navigator.pop(context);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final palette = MbongoThemeController.current;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: MbongoSubAppBar(title: 'Recharger la carte'),
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
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      palette.bannerGradient.first.withValues(alpha: 0.96),
                      palette.bannerGradient.last.withValues(alpha: 0.96),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.72)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Recharge securisee',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Carte virtuelle',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Rechargement',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Alimentez la carte sans casser la coherence du portefeuille principal.',
                      style: TextStyle(
                        color: Color(0xFFE8EEF8),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              VirtualBankCard(
                brand: (card['brand'] ?? 'VISA').toString(),
                holderName: (card['holderName'] ?? 'CLIENT MBONGO').toString(),
                maskedPan: card['maskedPan'].toString(),
                currency: (card['currency'] ?? 'USD').toString(),
                status: (card['status'] ?? 'ACTIVE').toString(),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card['maskedPan'].toString(),
                      style: TextStyle(
                        color: palette.accentStrong,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Solde actuel : ${card["currency"]} ${card["balance"]}',
                      style: const TextStyle(
                        color: AppColors.darkMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Montant a recharger',
                        hintText: '0.00',
                        prefixIcon: Icon(
                          Icons.account_balance_wallet_outlined,
                          color: palette.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : const Text('Valider le rechargement'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
