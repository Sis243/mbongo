import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../features/wallet/presentation/wallet_notifier.dart';
import '../../services/api_service.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/mbongo_sub_app_bar.dart';
import '../../widgets/common/transaction_confirm_sheet.dart';

class BillPayScreen extends ConsumerStatefulWidget {
  const BillPayScreen({super.key});

  @override
  ConsumerState<BillPayScreen> createState() => _BillPayScreenState();
}

class _BillPayScreenState extends ConsumerState<BillPayScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  static const _categories = [
    ('UTILITY',   'Utilitaires', Icons.bolt_rounded),
    ('INTERNET',  'Internet',    Icons.wifi_rounded),
    ('INSURANCE', 'Assurances',  Icons.shield_rounded),
  ];

  List<Map<String, dynamic>> _methods = [];
  bool _loading = true;
  bool _paying = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _categories.length, vsync: this);
    _loadMethods();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadMethods() async {
    try {
      final resp = await ApiService.getBillPayMethods();
      final list = resp['methods'];
      if (list is List) {
        setState(() {
          _methods = List<Map<String, dynamic>>.from(
            list.map((e) => Map<String, dynamic>.from(e as Map)),
          );
          _loading = false;
        });
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _methodsForCategory(String category) {
    return _methods.where((m) => m['category'] == category).toList();
  }

  Future<void> _onBillerTap(Map<String, dynamic> method) async {
    final palette = MbongoThemeController.current;
    final refCtrl = TextEditingController();
    final amtCtrl = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSt) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: palette.panel,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.30),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: palette.accentStrong.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _iconForCategory(method['category'] as String? ?? ''),
                          color: palette.accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              method['name'] as String? ?? '',
                              style: const TextStyle(
                                color: AppColors.text,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              method['description'] as String? ?? '',
                              style: const TextStyle(
                                color: AppColors.textSoft,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: refCtrl,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      labelText: method['referenceLabel'] as String? ??
                          'Numero de reference',
                      prefixIcon: const Icon(Icons.tag_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amtCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText:
                          'Montant (${method['currency'] ?? 'CDF'})',
                      prefixIcon: const Icon(Icons.payments_rounded),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: _paying
                        ? null
                        : () async {
                            final ref2 = refCtrl.text.trim();
                            final amtText =
                                amtCtrl.text.trim().replaceAll(',', '.');
                            final amt = double.tryParse(amtText);

                            if (ref2.isEmpty) {
                              _toast(
                                  'Veuillez saisir le numero de reference.');
                              return;
                            }
                            if (amt == null || amt <= 0) {
                              _toast('Veuillez saisir un montant valide.');
                              return;
                            }

                            final confirmed = await showTransactionConfirmSheet(
                              context: context,
                              title: 'Paiement facture',
                              icon: _iconForCategory(method['category'] as String? ?? ''),
                              rows: [
                                ConfirmRow(label: 'Service', value: method['name'] as String? ?? ''),
                                ConfirmRow(label: 'Référence', value: ref2),
                                ConfirmRow(label: 'Montant', value: '$amt ${method['currency'] ?? 'CDF'}', bold: true, valueColor: const Color(0xFFD4A843)),
                              ],
                            );
                            if (confirmed != true) return;
                            if (ctx.mounted) Navigator.pop(ctx);
                            setSt(() {});
                            await _submitPayment(
                              methodId:
                                  method['id'] as String? ?? '',
                              methodName:
                                  method['name'] as String? ?? '',
                              reference: ref2,
                              amount: amt,
                              currency: method['currency'] as String? ?? 'CDF',
                            );
                          },
                    child: const Text('Payer la facture'),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Future<void> _submitPayment({
    required String methodId,
    required String methodName,
    required String reference,
    required double amount,
    required String currency,
  }) async {
    setState(() => _paying = true);
    try {
      await ApiService.payBill(
        methodId: methodId,
        methodName: methodName,
        reference: reference,
        amount: amount,
      );

      await ref.read(walletProvider.notifier).refresh();

      if (!mounted) return;
      _showSuccessSheet(methodName: methodName, reference: reference, amount: amount, currency: currency);
    } catch (e) {
      if (!mounted) return;
      _toast(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  void _showSuccessSheet({
    required String methodName,
    required String reference,
    required double amount,
    required String currency,
  }) {
    final palette = MbongoThemeController.current;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D2B1A), Color(0xFF163D27)],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.green.withValues(alpha: 0.30),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.green, size: 52),
            const SizedBox(height: 14),
            const Text(
              'Facture payee',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$methodName — ref: $reference',
              style: const TextStyle(
                color: AppColors.textSoft,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${amount.toStringAsFixed(0)} $currency debites',
              style: TextStyle(
                color: palette.accent,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        ),
      ),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  IconData _iconForCategory(String cat) {
    return switch (cat) {
      'UTILITY'   => Icons.bolt_rounded,
      'TELECOM'   => Icons.phone_android_rounded,
      'TV'        => Icons.tv_rounded,
      'INTERNET'  => Icons.wifi_rounded,
      'INSURANCE' => Icons.shield_rounded,
      _           => Icons.receipt_long_rounded,
    };
  }

  Color _colorForCategory(String cat) {
    return switch (cat) {
      'UTILITY'   => AppColors.gold,
      'TELECOM'   => AppColors.cyan,
      'TV'        => const Color(0xFF9B59B6),
      'INTERNET'  => AppColors.green,
      'INSURANCE' => const Color(0xFFE74C3C),
      _           => MbongoThemeController.current.accent,
    };
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    final walletData = ref.watch(walletProvider).valueOrNull;
    final balance = walletData?.balance ?? 0.0;
    final currency = walletData?.currency ?? 'CDF';

    return AppScaffold(
      appBar: const MbongoSubAppBar(title: 'Paiement de factures'),
      useParticles: true,
      primaryParticleColor: palette.accent,
      secondaryParticleColor: AppColors.gold,
      particleDensity: 0.6,
      child: Column(
        children: [
          // Header balance card
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: palette.bannerGradient),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_rounded,
                    color: Colors.white, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Paiement de factures',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Solde: ${balance.toStringAsFixed(0)} $currency',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_paying)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),

          // Category tabs
          const SizedBox(height: 12),
          Container(
            color: Colors.transparent,
            child: TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              dividerColor: Colors.transparent,
              labelColor: palette.accent,
              unselectedLabelColor: AppColors.darkMuted,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(color: palette.accent, width: 2.5),
                borderRadius: BorderRadius.circular(2),
              ),
              tabs: _categories.map((c) {
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(c.$3, size: 15),
                      const SizedBox(width: 6),
                      Text(c.$2),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),

          // Tab views
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabs,
                    children: _categories.map((cat) {
                      final methods = _methodsForCategory(cat.$1);
                      if (methods.isEmpty) {
                        return const Center(
                          child: Text(
                            'Aucun facturier disponible',
                            style: TextStyle(
                              color: AppColors.darkMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                        itemCount: methods.length,
                        itemBuilder: (_, i) =>
                            _buildBillerCard(methods[i], palette),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillerCard(
      Map<String, dynamic> method, dynamic palette) {
    final cat = method['category'] as String? ?? '';
    final accent = _colorForCategory(cat);
    final name = method['name'] as String? ?? '';
    final desc = method['description'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.24),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _onBillerTap(method),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _iconForCategory(cat),
                    color: accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          desc,
                          style: const TextStyle(
                            color: AppColors.textSoft,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.darkMuted,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
