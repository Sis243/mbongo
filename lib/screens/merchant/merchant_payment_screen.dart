import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/dio_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../features/wallet/presentation/wallet_notifier.dart';
import '../../widgets/common/mbongo_money_particles.dart';
import '../../widgets/common/mbongo_sub_app_bar.dart';
import '../../widgets/common/transaction_confirm_sheet.dart';

final _merchantsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.read(dioClientProvider);
  final resp = await client.get('/merchant/accounts');
  final list = resp['data'];
  if (list is List) {
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  return [];
});

const _kMethods = ['Appareil', 'Carte', 'NFC', 'Liquide'];

class MerchantPaymentScreen extends ConsumerStatefulWidget {
  const MerchantPaymentScreen({super.key});

  @override
  ConsumerState<MerchantPaymentScreen> createState() =>
      _MerchantPaymentScreenState();
}

class _MerchantPaymentScreenState
    extends ConsumerState<MerchantPaymentScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _fmt(num v) => v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]} ',
      );

  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> list) {
    if (_query.isEmpty) return list;
    final q = _query.toLowerCase();
    return list.where((m) {
      final name = (m['name'] ?? '').toString().toLowerCase();
      final category = (m['category'] ?? '').toString().toLowerCase();
      final location = (m['location'] ?? '').toString().toLowerCase();
      return name.contains(q) || category.contains(q) || location.contains(q);
    }).toList();
  }

  void _openPaySheet(Map<String, dynamic> merchant) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaySheet(merchant: merchant),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    final merchantsAsync = ref.watch(_merchantsProvider);

    return Scaffold(
      backgroundColor: palette.shellBottom,
      appBar: MbongoSubAppBar(
        title: 'Payer un marchand',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.text),
            onPressed: () => ref.refresh(_merchantsProvider),
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
                  count: 10,
                  opacity: 0.07,
                  height: 0,
                ),
              ),
            ),
            SafeArea(
              child: merchantsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded,
                          color: AppColors.muted, size: 48),
                      const SizedBox(height: 12),
                      const Text('Impossible de charger les marchands.',
                          style: TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: () => ref.refresh(_merchantsProvider),
                        child: const Text('Reessayer'),
                      ),
                    ],
                  ),
                ),
                data: (merchants) {
                  final filtered = _filter(merchants);
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                        child: _buildHeader(palette, merchants.length),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: _buildSearch(palette),
                      ),
                      Expanded(
                        child: filtered.isEmpty
                            ? _buildEmpty()
                            : RefreshIndicator(
                                onRefresh: () => ref.refresh(_merchantsProvider.future),
                                child: ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 0, 16, 24),
                                  itemCount: filtered.length,
                                  itemBuilder: (_, i) => Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 12),
                                    child: _merchantTile(
                                        palette, filtered[i]),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(MbongoThemePalette palette, int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette.bannerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: palette.glow.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.storefront_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Paiement marchand',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count commerces disponibles',
                  style: const TextStyle(
                      color: Color(0xFFD0DDEE),
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch(MbongoThemePalette palette) {
    return TextField(
      controller: _searchCtrl,
      style: const TextStyle(color: AppColors.text, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Nom, categorie, localisation...',
        hintStyle:
            const TextStyle(color: AppColors.textSoft, fontSize: 13),
        prefixIcon:
            Icon(Icons.search_rounded, color: palette.accent, size: 20),
        suffixIcon: _query.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: AppColors.muted, size: 18),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() => _query = '');
                },
              )
            : null,
        filled: true,
        fillColor: palette.panel,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: AppColors.border.withValues(alpha: 0.30)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: AppColors.border.withValues(alpha: 0.30)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.accent, width: 1.4),
        ),
      ),
      onChanged: (v) => setState(() => _query = v.trim()),
    );
  }

  Widget _merchantTile(
      MbongoThemePalette palette, Map<String, dynamic> m) {
    final name = (m['name'] ?? '').toString();
    final category = (m['category'] ?? '').toString();
    final location = (m['location'] ?? '').toString();
    final volume = ((m['dailyVolume'] ?? 0) as num).toDouble();
    final terminals = ((m['terminals'] ?? 0) as num).toInt();

    return InkWell(
      onTap: () => _openPaySheet(m),
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.panelAlt,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: AppColors.border.withValues(alpha: 0.22)),
          boxShadow: const [
            BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: palette.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.storefront_rounded,
                  color: palette.accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w900,
                          fontSize: 14.5)),
                  const SizedBox(height: 3),
                  Text(
                    category.isNotEmpty && location.isNotEmpty
                        ? '$category · $location'
                        : category.isNotEmpty
                            ? category
                            : location,
                    style: const TextStyle(
                        color: AppColors.textSoft,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.memory_rounded,
                          size: 12, color: AppColors.muted),
                      const SizedBox(width: 3),
                      Text(
                        '$terminals terminal${terminals != 1 ? 's' : ''}',
                        style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                      if (volume > 0) ...[
                        const SizedBox(width: 10),
                        const Icon(Icons.trending_up_rounded,
                            size: 12, color: AppColors.green),
                        const SizedBox(width: 3),
                        Text(
                          'CDF ${_fmt(volume)}/j',
                          style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: palette.accent, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 48, color: AppColors.darkMuted),
            const SizedBox(height: 12),
            Text(
              _query.isNotEmpty
                  ? 'Aucun marchand ne correspond a "$_query".'
                  : 'Aucun marchand disponible.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.darkText, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaySheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> merchant;
  const _PaySheet({required this.merchant});

  @override
  ConsumerState<_PaySheet> createState() => _PaySheetState();
}

class _PaySheetState extends ConsumerState<_PaySheet> {
  final _amountCtrl = TextEditingController();
  String _method = 'Appareil';
  bool _loading = false;
  bool _paid = false;
  String? _error;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  String _fmt(num v) => v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]} ',
      );

  Future<void> _pay() async {
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amount <= 0) {
      setState(() => _error = 'Saisissez un montant valide.');
      return;
    }

    final name = (widget.merchant['name'] ?? '').toString();
    final confirmed = await showTransactionConfirmSheet(
      context: context,
      title: 'Paiement marchand',
      icon: Icons.storefront_rounded,
      rows: [
        ConfirmRow(label: 'Marchand', value: name),
        ConfirmRow(label: 'Méthode', value: _method),
        ConfirmRow(label: 'Montant', value: '${_amountCtrl.text.trim()} CDF', bold: true, valueColor: const Color(0xFFD4A843)),
      ],
    );
    if (!mounted || !confirmed) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = ref.read(dioClientProvider);
      await client.post('/transactions/merchant-pay', {
        'merchant': (widget.merchant['name'] ?? '').toString(),
        'amount': amount,
        'method': _method,
        'location': (widget.merchant['location'] ?? '').toString(),
      });
      ref.refresh(walletProvider.future).ignore();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _paid = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    final name = (widget.merchant['name'] ?? '').toString();
    final category = (widget.merchant['category'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
      ),
      child: _paid ? _buildSuccess(palette, name) : _buildForm(palette, name, category),
    );
  }

  Widget _buildSuccess(MbongoThemePalette palette, String name) {
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.green.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded,
              color: AppColors.green, size: 36),
        ),
        const SizedBox(height: 14),
        const Text(
          'Paiement confirme',
          style: TextStyle(
              color: AppColors.text,
              fontSize: 20,
              fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          'CDF ${_fmt(amount)} debite vers $name',
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: AppColors.textSoft,
              fontSize: 13.5,
              fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(
      MbongoThemePalette palette, String name, String category) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: palette.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.storefront_rounded,
                  color: palette.accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w900,
                          fontSize: 15)),
                  if (category.isNotEmpty)
                    Text(category,
                        style: const TextStyle(
                            color: AppColors.textSoft,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _amountCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(
              color: AppColors.text,
              fontSize: 18,
              fontWeight: FontWeight.w800),
          decoration: InputDecoration(
            hintText: 'Montant (CDF)',
            hintStyle: const TextStyle(color: AppColors.textSoft),
            prefixIcon:
                Icon(Icons.payments_rounded, color: palette.accent),
            filled: true,
            fillColor: palette.panel,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.30)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.30)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: palette.accent, width: 1.4),
            ),
          ),
          onChanged: (_) => setState(() => _error = null),
        ),
        const SizedBox(height: 14),
        Text(
          'Methode de paiement',
          style: TextStyle(
              color: palette.accent,
              fontSize: 12,
              fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _kMethods.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final selected = _kMethods[i] == _method;
              return GestureDetector(
                onTap: () => setState(() => _method = _kMethods[i]),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? palette.accent.withValues(alpha: 0.16)
                        : palette.panel,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? palette.accent
                          : AppColors.border.withValues(alpha: 0.30),
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    _kMethods[i],
                    style: TextStyle(
                      color: selected ? palette.accent : AppColors.textSoft,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(
            _error!,
            style: const TextStyle(
                color: AppColors.red,
                fontSize: 12.5,
                fontWeight: FontWeight.w700),
          ),
        ],
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _pay,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_circle_outline_rounded),
            label: Text(_loading ? 'Traitement...' : 'Confirmer le paiement'),
          ),
        ),
      ],
    );
  }
}
