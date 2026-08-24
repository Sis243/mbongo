import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/dio_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../core/utils/money.dart';
import '../../features/wallet/data/wallet_repository.dart';
import '../../features/wallet/presentation/wallet_notifier.dart';
import '../../models/account_model.dart';
import '../../widgets/cards/wallet_card.dart';
import '../../widgets/common/mbongo_money_particles.dart';
import '../../widgets/common/mbongo_sub_app_bar.dart';
import '../../widgets/common/transaction_confirm_sheet.dart';

class ExchangeMoneyScreen extends ConsumerStatefulWidget {
  const ExchangeMoneyScreen({super.key});

  @override
  ConsumerState<ExchangeMoneyScreen> createState() => _ExchangeMoneyScreenState();
}

class _ExchangeMoneyScreenState extends ConsumerState<ExchangeMoneyScreen> {
  String fromCurrency = 'CDF';
  String toCurrency = 'USD';

  final amountController = TextEditingController();
  bool isLoading = false;
  List<Map<String, dynamic>> _currencies = [];

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
  }

  Future<void> _loadCurrencies() async {
    try {
      final list = await ref.read(walletRepositoryProvider).fetchCurrencies();
      if (mounted) setState(() => _currencies = list);
    } catch (_) {}
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  double _parseAmount(String value) {
    return double.tryParse(value.replaceAll(',', '.').trim()) ?? 0;
  }

  double _rateFor(String code) {
    final entry = _currencies
        .where((c) => c['code'] == code || c['id'] == code)
        .firstOrNull;
    if (entry != null) {
      return ((entry['rate'] ?? 1) as num).toDouble();
    }
    return code == 'CDF' ? 2000.0 : 1.0;
  }

  double _convertedAmount(double amount) {
    final rateFrom = _rateFor(fromCurrency);
    final rateTo = _rateFor(toCurrency);
    if (rateFrom == 0) return 0;
    // amount / rateFrom gives USD equivalent, * rateTo gives target currency
    return amount / rateFrom * rateTo;
  }

  String _rateText() {
    final rateFrom = _rateFor(fromCurrency);
    final rateTo = _rateFor(toCurrency);
    if (rateFrom == 0) return '—';
    final converted = rateTo / rateFrom;
    return '1 $fromCurrency = ${converted.toStringAsFixed(converted < 1 ? 4 : 0)} $toCurrency';
  }

  void _switchCurrencies() {
    setState(() {
      final temp = fromCurrency;
      fromCurrency = toCurrency;
      toCurrency = temp;
    });
  }

  Future<void> _submit() async {
    final amount = _parseAmount(amountController.text);

    if (amount <= 0) {
      _toast("Veuillez saisir un montant valide.");
      return;
    }

    if (fromCurrency == toCurrency) {
      _toast("Les devises doivent etre differentes.");
      return;
    }

    final converted = _convertedAmount(amount);
    final confirmed = await showTransactionConfirmSheet(
      context: context,
      title: 'Échange de devises',
      icon: Icons.currency_exchange_rounded,
      rows: [
        ConfirmRow(label: 'Vous envoyez', value: '${Money.format(amount, fromCurrency)} $fromCurrency', bold: true, valueColor: const Color(0xFFD4A843)),
        ConfirmRow(label: 'Vous recevez', value: '${converted.toStringAsFixed(converted < 1 ? 4 : 2)} $toCurrency', bold: true, valueColor: const Color(0xFF4CAF50)),
        ConfirmRow(label: 'Taux appliqué', value: _rateText()),
      ],
    );
    if (!confirmed || !mounted) return;

    setState(() => isLoading = true);
    try {
      await ref.read(walletRepositoryProvider).exchange(
            fromCurrency: fromCurrency,
            toCurrency: toCurrency,
            amount: amount,
          );

      if (!mounted) return;
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Échange effectué : $amount $fromCurrency → ${converted.toStringAsFixed(2)} $toCurrency",
          ),
        ),
      );
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _toast(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _toast("Échange impossible pour le moment.");
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
    final selectedWallet = walletData != null
        ? AccountModel(
            id: walletData.id,
            type: 'Portefeuille ${walletData.currency}',
            currency: walletData.currency,
            number: 'MBONGO-${walletData.currency}',
            balance: walletData.balance,
            selected: true,
          )
        : null;
    final amount = _parseAmount(amountController.text);
    final converted = _convertedAmount(amount);

    return Scaffold(
      backgroundColor: palette.shellBottom,
      appBar: MbongoSubAppBar(title: 'Echange de monnaie'),
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
                  color: palette.accentStrong,
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
                  if (selectedWallet != null) ...[
                    const Text(
                      "Portefeuille source",
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
                  ],
                  const SizedBox(height: 18),
                  _buildSectionCard(
                    title: "Parametres d'echange",
                    icon: Icons.currency_exchange_rounded,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _currencyBox(
                                label: "De",
                                value: fromCurrency,
                                color: fromCurrency == 'CDF'
                                    ? palette.accent
                                    : palette.accentStrong,
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: _switchCurrencies,
                              child: Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: palette.accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.swap_horiz_rounded,
                                  color: palette.accent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _currencyBox(
                                label: "Vers",
                                value: toCurrency,
                                color: toCurrency == 'CDF'
                                    ? palette.accent
                                    : palette.accentStrong,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: palette.panel,
                            labelText: "Montant a echanger",
                            hintText: "Ex: 10000",
                            labelStyle: const TextStyle(color: AppColors.muted),
                            hintStyle: const TextStyle(color: AppColors.muted),
                            prefixIcon: Container(
                              width: 80,
                              alignment: Alignment.center,
                              child: Text(
                                Money.symbol(fromCurrency),
                                style: TextStyle(
                                  color: fromCurrency == 'CDF'
                                      ? palette.accent
                                      : palette.accentStrong,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
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
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: palette.panelAlt,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.trending_up_rounded,
                                color: palette.accentStrong,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Taux applique : ${_rateText()}",
                                  style: const TextStyle(
                                    color: AppColors.darkText,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPreviewCard(amount, converted),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.accentStrong,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text("Valider l'echange"),
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

  Widget _buildHeaderCard() {
    final palette = MbongoThemeController.current;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette.bannerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: palette.glow.withValues(alpha: 0.20),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: MbongoMoneyParticles(
                color: Colors.white,
                count: 14,
                opacity: 0.07,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.currency_exchange_rounded, color: palette.accentStrong),
                  SizedBox(width: 8),
                  Text(
                    "MBONGO Change",
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
                "Conversion de devises",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 6),
              Text(
                "Echangez vos CDF contre des USD ou l'inverse, au taux officiel MBONGO. La conversion est instantanee entre vos deux portefeuilles. Consultez le taux applique avant de valider.",
                style: TextStyle(
                  color: Color(0xFFE8EEF8),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final palette = MbongoThemeController.current;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(22),
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

  Widget _currencyBox({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: MbongoThemeController.current.panelAlt,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(double amount, double converted) {
    final palette = MbongoThemeController.current;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.visibility_rounded, color: AppColors.gold),
              SizedBox(width: 8),
              Text(
                "Apercu de l'operation",
                style: TextStyle(
                  color: AppColors.darkText,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _previewBox(
                  "Montant envoye",
                  "${Money.symbol(fromCurrency)} ${amount.toStringAsFixed(2)}",
                  fromCurrency == 'CDF' ? palette.accent : palette.accentStrong,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _previewBox(
                  "Montant recu",
                  "${Money.symbol(toCurrency)} ${converted.toStringAsFixed(2)}",
                  toCurrency == 'CDF' ? palette.accent : palette.accentStrong,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _previewBox(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MbongoThemeController.current.panelAlt,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
