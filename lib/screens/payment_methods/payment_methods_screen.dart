import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/dio_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../widgets/common/mbongo_money_particles.dart';


final _depositMethodsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.read(dioClientProvider);
  final resp = await client.get('/wallet/deposit-methods');
  final list = resp['data'];
  if (list is List) {
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  return [];
});

final _withdrawMethodsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.read(dioClientProvider);
  final resp = await client.get('/wallet/withdraw-methods');
  final list = resp['data'];
  if (list is List) {
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  return [];
});

class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  ConsumerState<PaymentMethodsScreen> createState() =>
      _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState
    extends ConsumerState<PaymentMethodsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.refresh(_depositMethodsProvider.future).ignore();
    ref.refresh(_withdrawMethodsProvider.future).ignore();
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;

    return Scaffold(
      backgroundColor: palette.shellBottom,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: palette.shellTop,
        elevation: 0,
        centerTitle: false,
        leadingWidth: 112,
        titleSpacing: 8,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
          child: InkWell(
            onTap: () => Navigator.maybePop(context),
            borderRadius: BorderRadius.circular(8),
            child: Ink(
              decoration: BoxDecoration(
                color: palette.panelAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.24)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_back_ios_new_rounded,
                      color: palette.accent, size: 16),
                  const SizedBox(width: 6),
                  const Text(
                    'Retour',
                    style: TextStyle(
                        color: AppColors.darkText,
                        fontSize: 13,
                        fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
        ),
        title: const Text(
          'Methodes de paiement',
          style: TextStyle(
              color: AppColors.text,
              fontSize: 20,
              fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.text),
            onPressed: _refresh,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: palette.accent,
          labelColor: palette.accent,
          unselectedLabelColor: AppColors.textSoft,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          tabs: const [
            Tab(text: 'Depot'),
            Tab(text: 'Retrait'),
          ],
        ),
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
              child: TabBarView(
                controller: _tabs,
                children: [
                  _MethodsList(
                    provider: _depositMethodsProvider,
                    emptyLabel: 'Aucune methode de depot disponible.',
                    accentColor: AppColors.green,
                    icon: Icons.arrow_downward_rounded,
                  ),
                  _MethodsList(
                    provider: _withdrawMethodsProvider,
                    emptyLabel: 'Aucune methode de retrait disponible.',
                    accentColor: AppColors.orange,
                    icon: Icons.arrow_upward_rounded,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodsList extends ConsumerWidget {
  final FutureProvider<List<Map<String, dynamic>>> provider;
  final String emptyLabel;
  final Color accentColor;
  final IconData icon;

  const _MethodsList({
    required this.provider,
    required this.emptyLabel,
    required this.accentColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = MbongoThemeController.current;
    final async = ref.watch(provider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: AppColors.muted, size: 48),
            const SizedBox(height: 12),
            const Text('Impossible de charger les methodes.',
                style: TextStyle(
                    color: AppColors.muted, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () => ref.refresh(provider),
              child: const Text('Reessayer'),
            ),
          ],
        ),
      ),
      data: (methods) => methods.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon,
                        size: 48, color: AppColors.darkMuted),
                    const SizedBox(height: 12),
                    Text(
                      emptyLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.darkText,
                          fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: () => ref.refresh(provider.future),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: methods.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _methodCard(palette, methods[i], accentColor, icon),
                ),
              ),
            ),
    );
  }

  Widget _methodCard(
    MbongoThemePalette palette,
    Map<String, dynamic> m,
    Color color,
    IconData icon,
  ) {
    final name = (m['name'] ?? '').toString();
    final description = (m['description'] ?? '').toString();
    final instructions = (m['instructions'] ?? '').toString();
    final minAmount = m['minAmount'];
    final maxAmount = m['maxAmount'];
    final fees = m['fees'];
    final processingTime = (m['processingTime'] ?? '').toString();

    return Container(
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.22)),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name.isEmpty ? 'Methode' : name,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 14.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Actif',
                    style: TextStyle(
                        color: AppColors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (description.isNotEmpty) ...[
                  Text(
                    description,
                    style: const TextStyle(
                        color: AppColors.textSoft,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.4),
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    if (minAmount != null)
                      Expanded(
                        child: _infoCell(
                          'Minimum',
                          '$minAmount CDF',
                          AppColors.darkMuted,
                        ),
                      ),
                    if (minAmount != null && maxAmount != null)
                      const SizedBox(width: 8),
                    if (maxAmount != null)
                      Expanded(
                        child: _infoCell(
                          'Maximum',
                          '$maxAmount CDF',
                          AppColors.darkMuted,
                        ),
                      ),
                  ],
                ),
                if (minAmount != null || maxAmount != null)
                  const SizedBox(height: 8),
                Row(
                  children: [
                    if (fees != null)
                      Expanded(
                        child: _infoCell(
                          'Frais',
                          fees.toString(),
                          AppColors.gold,
                        ),
                      ),
                    if (fees != null && processingTime.isNotEmpty)
                      const SizedBox(width: 8),
                    if (processingTime.isNotEmpty)
                      Expanded(
                        child: _infoCell(
                          'Delai',
                          processingTime,
                          palette.accent,
                        ),
                      ),
                  ],
                ),
                if (instructions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: palette.panel,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.18)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                color: palette.accent, size: 14),
                            const SizedBox(width: 5),
                            Text(
                              'Instructions',
                              style: TextStyle(
                                  color: palette.accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          instructions,
                          style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCell(String label, String value, Color valueColor) {
    final palette = MbongoThemeController.current;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: AppColors.border.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.darkMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(
                  color: valueColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
