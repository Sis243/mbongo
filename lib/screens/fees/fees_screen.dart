import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/dio_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../widgets/common/mbongo_money_particles.dart';
import '../../widgets/common/mbongo_sub_app_bar.dart';

final _feesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.read(dioClientProvider);
  final resp = await client.get('/wallet/fees');
  final list = resp['data'];
  if (list is List) {
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  return [];
});

class FeesScreen extends ConsumerWidget {
  const FeesScreen({super.key});

  String _fmt(num v) {
    return v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ',
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = MbongoThemeController.current;
    final feesAsync = ref.watch(_feesProvider);

    return Scaffold(
      backgroundColor: palette.shellBottom,
      appBar: MbongoSubAppBar(
        title: 'Grille tarifaire',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.text),
            onPressed: () => ref.refresh(_feesProvider),
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
                  color: palette.accent,
                  count: 12,
                  opacity: 0.07,
                  height: 0,
                ),
              ),
            ),
            SafeArea(
              child: feesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded, color: AppColors.muted, size: 48),
                      const SizedBox(height: 12),
                      const Text('Impossible de charger les tarifs.',
                          style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: () => ref.refresh(_feesProvider),
                        child: const Text('Reessayer'),
                      ),
                    ],
                  ),
                ),
                data: (fees) => RefreshIndicator(
                  onRefresh: () => ref.refresh(_feesProvider.future),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildHeaderCard(palette),
                      const SizedBox(height: 18),
                      _buildInfoCard(palette),
                      const SizedBox(height: 18),
                      if (fees.isEmpty)
                        _buildEmpty(palette)
                      else
                        ...fees.map((f) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _feeTile(palette, f),
                            )),
                    ],
                  ),
                ),
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
              Icon(Icons.price_check_rounded, color: palette.accentStrong),
              const SizedBox(width: 8),
              const Text(
                'Grille tarifaire',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Frais et limites',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Consultez les frais appliques a chaque type d\'operation ainsi que les limites journalieres et mensuelles en vigueur sur votre compte.',
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

  Widget _buildInfoCard(MbongoThemePalette palette) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: palette.accent, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Les frais sont debites automatiquement lors de chaque operation. Les limites s\'appliquent par periode de 24h ou 30 jours glissants.',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _feeTile(MbongoThemePalette palette, Map<String, dynamic> f) {
    final title = (f['title'] ?? '').toString();
    final fixedFee = ((f['fixedFee'] ?? 0) as num).toDouble();
    final percentFee = ((f['percentFee'] ?? 0) as num).toDouble();
    final minAmount = ((f['minAmount'] ?? 0) as num).toDouble();
    final maxAmount = ((f['maxAmount'] ?? 0) as num).toDouble();
    final dailyLimit = ((f['dailyLimit'] ?? 0) as num).toDouble();
    final monthlyLimit = ((f['monthlyLimit'] ?? 0) as num).toDouble();
    final currency = (f['currency'] ?? 'CDF').toString();

    return Container(
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: palette.accent.withValues(alpha: 0.10),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(Icons.receipt_long_rounded, color: palette.accent, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: palette.accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _cell(
                        'Frais fixes',
                        fixedFee == 0 ? 'Gratuit' : '${_fmt(fixedFee)} $currency',
                        fixedFee == 0 ? AppColors.green : AppColors.gold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _cell(
                        'Frais %',
                        percentFee == 0 ? '0 %' : '${percentFee.toStringAsFixed(1)} %',
                        percentFee == 0 ? AppColors.green : AppColors.gold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _cell('Min.', '${_fmt(minAmount)} $currency', AppColors.darkMuted),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _cell('Max.', '${_fmt(maxAmount)} $currency', AppColors.darkMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _cell('Limite / jour', '${_fmt(dailyLimit)} $currency', palette.accent),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _cell('Limite / mois', '${_fmt(monthlyLimit)} $currency', palette.accent),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(String label, String value, Color valueColor) {
    final palette = MbongoThemeController.current;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.darkMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(MbongoThemePalette palette) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
      ),
      child: const Column(
        children: [
          Icon(Icons.price_check_rounded, size: 42, color: AppColors.darkMuted),
          SizedBox(height: 10),
          Text(
            'Aucune grille tarifaire disponible pour le moment.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
