import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/dio_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../features/wallet/presentation/wallet_notifier.dart';
import '../../widgets/common/mbongo_money_particles.dart';
import '../../widgets/common/mbongo_sub_app_bar.dart';

final _ratesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.read(dioClientProvider);
  final resp = await client.get('/merchant/currencies');
  final list = resp['data'] ?? resp;
  if (list is List) {
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  return [];
});

class ExchangeRatesScreen extends ConsumerStatefulWidget {
  const ExchangeRatesScreen({super.key});

  @override
  ConsumerState<ExchangeRatesScreen> createState() => _ExchangeRatesScreenState();
}

class _ExchangeRatesScreenState extends ConsumerState<ExchangeRatesScreen> {
  final fromCtrl = TextEditingController();
  String fromCurrency = 'CDF';
  String toCurrency = 'USD';
  double convertedResult = 0;

  @override
  void dispose() {
    fromCtrl.dispose();
    super.dispose();
  }

  void _convert(List<Map<String, dynamic>> currencies) {
    final amount = double.tryParse(fromCtrl.text.trim().replaceAll(',', '.')) ?? 0;
    if (amount <= 0) {
      setState(() => convertedResult = 0);
      return;
    }

    final fromC = currencies.firstWhere(
      (c) => c['code'] == fromCurrency,
      orElse: () => {'rate': 1.0},
    );
    final toC = currencies.firstWhere(
      (c) => c['code'] == toCurrency,
      orElse: () => {'rate': 1.0},
    );

    final fromRate = ((fromC['rate'] ?? 1) as num).toDouble();
    final toRate = ((toC['rate'] ?? 1) as num).toDouble();

    // Convert to base (CDF) then to target
    double result;
    if (fromCurrency == 'CDF') {
      result = amount / toRate;
    } else if (toCurrency == 'CDF') {
      result = amount * fromRate;
    } else {
      result = (amount * fromRate) / toRate;
    }

    setState(() => convertedResult = result);
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    final ratesAsync = ref.watch(_ratesProvider);
    final walletCurrency = ref.watch(walletProvider).valueOrNull?.currency ?? 'CDF';

    return Scaffold(
      backgroundColor: palette.shellBottom,
      appBar: MbongoSubAppBar(
        title: 'Taux de change',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.text),
            onPressed: () => ref.refresh(_ratesProvider),
          ),
        ],
      ),
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
                  count: 12,
                  opacity: 0.07,
                  height: 0,
                ),
              ),
            ),
            SafeArea(
              child: ratesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded, color: AppColors.muted, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'Impossible de charger les taux.',
                        style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: () => ref.refresh(_ratesProvider),
                        child: const Text('Reessayer'),
                      ),
                    ],
                  ),
                ),
                data: (currencies) {
                  final codes = currencies.map((c) => c['code'].toString()).toList();
                  if (!codes.contains(fromCurrency)) fromCurrency = codes.isNotEmpty ? codes[0] : 'CDF';
                  if (!codes.contains(toCurrency) && codes.length > 1) toCurrency = codes[1];

                  return RefreshIndicator(
                    onRefresh: () => ref.refresh(_ratesProvider.future),
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildHeaderCard(palette, walletCurrency),
                        const SizedBox(height: 18),
                        _buildConverterCard(palette, currencies, codes),
                        const SizedBox(height: 18),
                        _buildRatesCard(palette, currencies),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(MbongoThemePalette palette, String walletCurrency) {
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
              Icon(Icons.currency_exchange_rounded, color: palette.accentStrong),
              const SizedBox(width: 8),
              const Text(
                'Taux de change',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Cours des devises',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Consultez les taux de change en temps reel et convertissez facilement entre les devises disponibles sur MBONGO.',
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

  Widget _buildConverterCard(
    MbongoThemePalette palette,
    List<Map<String, dynamic>> currencies,
    List<String> codes,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 14, offset: Offset(0, 7)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.swap_horiz_rounded, color: palette.accent),
              const SizedBox(width: 8),
              const Text(
                'Convertisseur',
                style: TextStyle(color: AppColors.darkText, fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _currencyDropdown(palette, codes, fromCurrency, (v) {
                  if (v != null) setState(() => fromCurrency = v);
                }),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() {
                      final tmp = fromCurrency;
                      fromCurrency = toCurrency;
                      toCurrency = tmp;
                      _convert(currencies);
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: palette.accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.swap_horiz_rounded, color: palette.accent, size: 20),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _currencyDropdown(palette, codes, toCurrency, (v) {
                  if (v != null) setState(() => toCurrency = v);
                }),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: fromCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => _convert(currencies),
            style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              filled: true,
              fillColor: palette.panel,
              labelText: 'Montant à convertir',
              hintText: '0.00',
              labelStyle: const TextStyle(color: AppColors.muted),
              hintStyle: const TextStyle(color: AppColors.muted),
              prefixIcon: const Icon(Icons.payments_outlined, color: AppColors.primary),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.24)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: palette.accent, width: 1.4),
              ),
            ),
          ),
          if (convertedResult > 0) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.accent.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    '${fromCtrl.text} $fromCurrency =',
                    style: const TextStyle(
                      color: AppColors.darkMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${convertedResult.toStringAsFixed(4)} $toCurrency',
                    style: TextStyle(
                      color: palette.accent,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _currencyDropdown(
    MbongoThemePalette palette,
    List<String> codes,
    String value,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: codes.contains(value) ? value : codes.first,
          dropdownColor: palette.panel,
          style: TextStyle(
            color: palette.accent,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
          items: codes
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildRatesCard(MbongoThemePalette palette, List<Map<String, dynamic>> currencies) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 14, offset: Offset(0, 7)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: palette.accent),
              const SizedBox(width: 8),
              const Text(
                'Toutes les devises',
                style: TextStyle(color: AppColors.darkText, fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...currencies.map((c) => _rateTile(palette, c)),
        ],
      ),
    );
  }

  Widget _rateTile(MbongoThemePalette palette, Map<String, dynamic> c) {
    final code = c['code']?.toString() ?? '';
    final name = c['name']?.toString() ?? '';
    final symbol = c['symbol']?.toString() ?? '';
    final rate = ((c['rate'] ?? 1) as num).toDouble();
    final rateLabel = c['rateLabel']?.toString() ?? '';
    final isDefault = c['isDefault'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDefault ? const Color(0xFF102A55) : palette.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDefault
              ? palette.accent.withValues(alpha: 0.5)
              : AppColors.border.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              symbol,
              style: TextStyle(
                color: palette.accent,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$code — $name',
                  style: TextStyle(
                    color: isDefault ? Colors.white : AppColors.darkText,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                if (rateLabel.isNotEmpty)
                  Text(
                    rateLabel,
                    style: TextStyle(
                      color: isDefault ? const Color(0xFFB8CDE8) : AppColors.darkMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                rate.toStringAsFixed(rate >= 100 ? 0 : 4),
                style: TextStyle(
                  color: isDefault ? Colors.white : palette.accent,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              Text(
                'par CDF',
                style: TextStyle(
                  color: isDefault ? const Color(0xFFB8CDE8) : AppColors.darkMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
