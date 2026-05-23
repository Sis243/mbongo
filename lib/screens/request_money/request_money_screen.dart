import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../core/utils/money.dart';
import '../../features/wallet/data/wallet_repository.dart';
import '../../features/wallet/presentation/wallet_notifier.dart';
import '../../widgets/common/mbongo_money_particles.dart';
import 'request_money_success_screen.dart';
import '../../widgets/common/mbongo_sub_app_bar.dart';

class RequestMoneyScreen extends ConsumerStatefulWidget {
  const RequestMoneyScreen({super.key});

  @override
  ConsumerState<RequestMoneyScreen> createState() => _RequestMoneyScreenState();
}

class _RequestMoneyScreenState extends ConsumerState<RequestMoneyScreen> {
  int channelIndex = 0;
  bool _submitting = false;

  final amountController = TextEditingController();
  final phoneController = TextEditingController();
  final reasonController = TextEditingController();

  final List<String> channels = ['Mbongo', 'Alias', 'Compte'];

  @override
  void dispose() {
    amountController.dispose();
    phoneController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final walletData = ref.read(walletProvider).valueOrNull;
    final currency = walletData?.currency ?? 'CDF';
    final amount =
        double.tryParse(amountController.text.trim().replaceAll(',', '.'));

    if (amount == null || amount <= 0) {
      _toast("Veuillez saisir un montant valide.");
      return;
    }

    if (phoneController.text.trim().isEmpty) {
      _toast("Veuillez renseigner le telephone ou identifiant.");
      return;
    }

    if (reasonController.text.trim().isEmpty) {
      _toast("Veuillez renseigner le motif.");
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(walletRepositoryProvider).requestMoney(
            amount: amount,
            targetPhone: phoneController.text.trim(),
            reason: reasonController.text.trim(),
            channel: channels[channelIndex],
          );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RequestMoneySuccessScreen(
            amount: amount,
            currency: currency,
            channel: channels[channelIndex],
            phone: phoneController.text.trim(),
            reason: reasonController.text.trim(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _toast(e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    final walletData = ref.watch(walletProvider).valueOrNull;
    final currency = walletData?.currency ?? 'CDF';

    return Scaffold(
      backgroundColor: palette.shellBottom,
      appBar: MbongoSubAppBar(title: "Demande d'Argent"),
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
                  _buildHeaderCard(),
                  const SizedBox(height: 18),
                  if (walletData != null)
                    _buildBalanceCard(walletData.balance, currency, palette),
                  const SizedBox(height: 18),
                  _buildLightCard(
                    title: "Canal de demande",
                    icon: Icons.compare_arrows_rounded,
                    child: Row(
                      children: List.generate(channels.length, (i) {
                        final selected = i == channelIndex;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: i == channels.length - 1 ? 0 : 10,
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(18),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () => setState(() => channelIndex = i),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? palette.accent
                                        : palette.panelAlt,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: selected
                                          ? palette.accent
                                          : AppColors.border.withValues(alpha: 0.65),
                                    ),
                                  ),
                                  child: Text(
                                    channels[i],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : palette.accentStrong,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLightCard(
                    title: "Informations de la demande",
                    icon: Icons.request_quote_outlined,
                    child: Column(
                      children: [
                        _textField(
                          controller: amountController,
                          label: "Montant",
                          hint: "Ex: 500",
                          prefix: Text(
                            Money.symbol(currency),
                            style: TextStyle(
                              color: currency == "CDF"
                                  ? palette.accent
                                  : palette.accentStrong,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          keyboard:
                              const TextInputType.numberWithOptions(decimal: true),
                        ),
                        const SizedBox(height: 14),
                        _textField(
                          controller: phoneController,
                          label: channels[channelIndex] == 'Compte'
                              ? "Numero de compte / telephone"
                              : "Telephone / identifiant",
                          hint: "+243 XXX XXX XXX",
                          icon: Icons.phone_outlined,
                        ),
                        const SizedBox(height: 14),
                        _textField(
                          controller: reasonController,
                          label: "Motif",
                          hint: "Ex: Paiement de service",
                          icon: Icons.edit_note_outlined,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.accentStrong,
                    ),
                    child: Text(_submitting ? "Envoi en cours..." : "Envoyer la demande"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(double balance, String currency, MbongoThemePalette palette) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette.cardGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: palette.glow.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 28),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Solde disponible",
                style: TextStyle(color: Color(0xFFE8EEF8), fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                "$currency ${balance.toStringAsFixed(2)}",
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    final palette = MbongoThemeController.current;
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
              Icon(Icons.request_page_rounded, color: palette.accentStrong),
              SizedBox(width: 8),
              Text(
                "Demande d'Argent",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            "Creer une demande",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "Envoyez une demande de paiement a un contact via son numero MBONGO, alias ou numero de compte. Le beneficiaire peut honorer la demande depuis son propre portefeuille.",
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

  Widget _buildLightCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final palette = MbongoThemeController.current;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
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
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.darkText,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
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

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    Widget? prefix,
    IconData? icon,
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    final palette = MbongoThemeController.current;
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: const TextStyle(
        color: AppColors.text,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: palette.panel,
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppColors.muted),
        hintStyle: const TextStyle(color: AppColors.muted),
        prefixIcon: prefix != null
            ? Container(
                width: 70,
                alignment: Alignment.center,
                child: prefix,
              )
            : icon != null
                ? Icon(icon, color: palette.accent)
                : null,
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
    );
  }
}
