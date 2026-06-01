import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/dio_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../core/utils/money.dart';
import '../../features/wallet/data/wallet_repository.dart';
import '../../features/wallet/presentation/wallet_notifier.dart';
import '../../models/account_model.dart';
import '../../widgets/common/mbongo_sub_app_bar.dart';
import '../../widgets/common/transaction_confirm_sheet.dart';
import '../../widgets/cards/wallet_card.dart';
import '../../widgets/common/mbongo_money_particles.dart';
import 'buy_airtime_success_screen.dart';

class BuyAirtimeScreen extends ConsumerStatefulWidget {
  const BuyAirtimeScreen({super.key});

  @override
  ConsumerState<BuyAirtimeScreen> createState() => _BuyAirtimeScreenState();
}

class _BuyAirtimeScreenState extends ConsumerState<BuyAirtimeScreen> {
  int operatorIndex = 0;

  final phoneController = TextEditingController();
  final amountController = TextEditingController();

  final List<Map<String, dynamic>> operators = const [
    {
      "name": "Vodacom",
      "color": Color(0xFFE30613),
      "icon": Icons.network_cell,
    },
    {
      "name": "Airtel",
      "color": Color(0xFFD71920),
      "icon": Icons.sim_card_rounded,
    },
    {
      "name": "Orange",
      "color": Color(0xFFFF7900),
      "icon": Icons.wifi_tethering_rounded,
    },
    {
      "name": "Africell",
      "color": Color(0xFF0057B8),
      "icon": Icons.signal_cellular_alt_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    phoneController.dispose();
    amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final walletData = ref.read(walletProvider).valueOrNull;
    final currency = walletData?.currency ?? 'CDF';
    final operator = operators[operatorIndex]["name"].toString();
    final amount =
        double.tryParse(amountController.text.trim().replaceAll(",", "."));

    if (phoneController.text.trim().isEmpty) {
      _toast("Veuillez renseigner le numero de telephone.");
      return;
    }

    if (phoneController.text.trim().length < 8) {
      _toast("Numero de telephone invalide.");
      return;
    }

    if (amount == null || amount <= 0) {
      _toast("Veuillez entrer un montant valide.");
      return;
    }

    if (currency == "CDF" && amount < 500) {
      _toast("Le minimum d'achat en CDF est 500.");
      return;
    }

    if (currency == "USD" && amount < 1) {
      _toast("Le minimum d'achat en USD est 1.");
      return;
    }

    final confirmed = await showTransactionConfirmSheet(
      context: context,
      title: 'Recharge Airtime',
      icon: Icons.sim_card_rounded,
      rows: [
        ConfirmRow(label: 'Opérateur', value: operator),
        ConfirmRow(label: 'Numéro', value: phoneController.text.trim()),
        ConfirmRow(label: 'Montant', value: '$amount $currency', bold: true, valueColor: const Color(0xFFD4A843)),
      ],
    );
    if (!mounted || !confirmed) return;

    try {
      await ref.read(walletRepositoryProvider).buyAirtime(
            operatorName: operator,
            phone: phoneController.text.trim(),
            amount: amount,
          );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BuyAirtimeSuccessScreen(
            operatorName: operator,
            phone: phoneController.text.trim(),
            amount: amount,
            currency: currency,
          ),
        ),
      );
    } on ApiException catch (error) {
      _toast(error.message);
    } catch (_) {
      _toast("Operation impossible pour le moment.");
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletData = ref.watch(walletProvider).valueOrNull;
    final selectedWallet = walletData != null
        ? AccountModel(
            id: walletData.id,
            type: 'Portefeuille ${walletData.currency}',
            currency: walletData.currency,
            number: 'MBONGO-${walletData.currency}',
            balance: walletData.balance,
            selected: true,
          )
        : AccountModel(
            id: '',
            type: 'Portefeuille CDF',
            currency: 'CDF',
            number: 'MBONGO-CDF',
            balance: 0,
            selected: true,
          );
    final palette = MbongoThemeController.current;

    return Scaffold(
      backgroundColor: palette.shellBottom,
      appBar: MbongoSubAppBar(title: "Achat d'unites"),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.shellTop, palette.shellBottom],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: MbongoMoneyParticles(
                  color: palette.accent,
                  count: 14,
                  opacity: 0.08,
                  height: 0,
                ),
              ),
            ),
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeaderCard(palette),
                  const SizedBox(height: 18),
                  const Text(
                    "Portefeuille selectionne",
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  WalletCard(
                    wallet: selectedWallet,
                    gradient: selectedWallet.currency == "CDF"
                        ? palette.cardGradient
                        : [palette.cardGradient.first, palette.accentStrong],
                  ),
                  const SizedBox(height: 18),
                  _buildSectionCard(
                    title: "Choisir l'operateur",
                    icon: Icons.cell_tower_rounded,
                    palette: palette,
                    child: GridView.builder(
                      itemCount: operators.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        mainAxisExtent: 86,
                      ),
                      itemBuilder: (_, i) {
                        final item = operators[i];
                        final selected = i == operatorIndex;
                        final color = item["color"] as Color;

                        return Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => setState(() => operatorIndex = i),
                            child: Container(
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFF102A55)
                                    : palette.panel,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: selected
                                      ? color
                                      : AppColors.border.withValues(alpha: 0.40),
                                  width: selected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    item["icon"] as IconData,
                                    color: selected ? Colors.white : color,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    item["name"].toString(),
                                    style: TextStyle(
                                      color: selected ? Colors.white : AppColors.text,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: "Informations de recharge",
                    icon: Icons.phone_android_rounded,
                    palette: palette,
                    child: Column(
                      children: [
                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: palette.panel,
                            labelText: "Numero de telephone",
                            hintText: "+243 XXX XXX XXX",
                            labelStyle: const TextStyle(color: AppColors.muted),
                            hintStyle: const TextStyle(color: AppColors.muted),
                            prefixIcon: const Icon(
                              Icons.phone_outlined,
                              color: AppColors.primary,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: AppColors.border.withValues(alpha: 0.24),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: palette.accent,
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: const TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w700,
                          ),
                            decoration: InputDecoration(
                            filled: true,
                            fillColor: palette.panel,
                            labelText: "Montant",
                            hintText: "0,00",
                            labelStyle: const TextStyle(color: AppColors.muted),
                            hintStyle: const TextStyle(color: AppColors.muted),
                            prefixIcon: Container(
                              width: 80,
                              alignment: Alignment.center,
                              child: Text(
                                Money.symbol(selectedWallet.currency),
                                style: TextStyle(
                                  color: selectedWallet.currency == "CDF"
                                      ? palette.accent
                                      : palette.accentStrong,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: AppColors.border.withValues(alpha: 0.24),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: palette.accent,
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.accentStrong,
                    ),
                    child: const Text("Acheter maintenant"),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: palette.accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: palette.accent.withValues(alpha: 0.26),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, color: palette.accent),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            "Le montant sera debite de votre portefeuille selectionne apres validation.",
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildHeaderCard(MbongoThemePalette palette) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette.bannerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
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
              Icon(Icons.phone_android_rounded, color: palette.accentStrong),
              const SizedBox(width: 8),
              const Text(
                "Achat d'unites",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "Recharge telephonique",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Rechargez votre numero ou celui d'un tiers en unites ou forfait data. Operateurs compatibles : Vodacom, Airtel, Orange, Africell. Le debit est immediat depuis votre portefeuille actif.",
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

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required MbongoThemePalette palette,
    required Widget child,
  }) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: palette.accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.darkText,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
