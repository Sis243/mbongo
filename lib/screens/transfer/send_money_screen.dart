import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/dio_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../core/utils/money.dart';
import '../../features/wallet/data/wallet_repository.dart';
import '../../services/kyc_guard_service.dart';
import '../../widgets/common/kyc_action_banner.dart';
import '../../widgets/common/mbongo_money_particles.dart';
import '../../widgets/common/mbongo_sub_app_bar.dart';
import '../../widgets/common/transaction_confirm_sheet.dart';
import '../profile/kyc_status_screen.dart';
import '../register_screen.dart';
import 'send_money_success_screen.dart';

// ─────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────
class _MbongoUser {
  final String id;
  final String name;
  final String phone;
  final String initials;
  const _MbongoUser({required this.id, required this.name, required this.phone, required this.initials});

  factory _MbongoUser.fromJson(Map<String, dynamic> j) => _MbongoUser(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        phone: j['phone']?.toString() ?? '',
        initials: j['initials']?.toString() ?? '?',
      );

  String get maskedPhone {
    if (phone.length <= 4) return phone;
    final visible = phone.substring(phone.length - 4);
    final prefix = phone.length > 7 ? phone.substring(0, 4) : phone.substring(0, 3);
    return '$prefix ···· $visible';
  }
}

// ─────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────
class SendMoneyScreen extends ConsumerStatefulWidget {
  const SendMoneyScreen({super.key});

  @override
  ConsumerState<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends ConsumerState<SendMoneyScreen> {
  // Phase : 0 = recherche bénéficiaire, 1 = saisie montant
  int _phase = 0;

  final _searchCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();

  List<_MbongoUser> _results = [];
  bool _searching = false;
  String _searchError = '';
  _MbongoUser? _selected;

  String _currency = 'CDF';
  bool _submitting = false;

  Timer? _debounce;

  KycAccess _kycAccess = const KycAccess(
    allowed: false,
    status: 'non_commence',
    message: 'Vérification en cours...',
  );

  @override
  void initState() {
    super.initState();
    _loadKycAccess();
  }

  Future<void> _loadKycAccess() async {
    final access = await KycGuardService.sensitiveOperationAccess();
    if (!mounted) return;
    setState(() => _kycAccess = access);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() { _results = []; _searchError = ''; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _runSearch(value.trim()));
  }

  Future<void> _runSearch(String q) async {
    setState(() { _searching = true; _searchError = ''; });
    try {
      final client = ref.read(dioClientProvider);
      final resp = await client.get('/users/search?q=${Uri.encodeQueryComponent(q)}');
      final list = resp['users'];
      if (!mounted) return;
      setState(() {
        _results = list is List
            ? list.map((e) => _MbongoUser.fromJson(Map<String, dynamic>.from(e as Map))).toList()
            : [];
        _searching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _searching = false; _searchError = 'Recherche indisponible.'; });
    }
  }

  void _selectUser(_MbongoUser user) {
    setState(() {
      _selected = user;
      _phase = 1;
      _results = [];
      _searchCtrl.text = user.name;
    });
  }

  void _clearSelection() {
    setState(() {
      _selected = null;
      _phase = 0;
      _searchCtrl.clear();
      _amountCtrl.clear();
      _reasonCtrl.clear();
    });
  }

  Future<void> _submit() async {
    if (!_kycAccess.allowed) { _toast(_kycAccess.message); return; }
    final user = _selected;
    if (user == null) { _toast('Veuillez sélectionner un bénéficiaire.'); return; }

    final amount = double.tryParse(_amountCtrl.text.trim().replaceAll(',', '.')) ?? 0;
    if (amount <= 0) { _toast('Veuillez saisir un montant valide.'); return; }

    final reason = _reasonCtrl.text.trim().isEmpty ? "Transfert d'argent" : _reasonCtrl.text.trim();

    final confirmed = await showTransactionConfirmSheet(
      context: context,
      title: "Envoi d'argent",
      icon: Icons.send_rounded,
      rows: [
        ConfirmRow(label: 'Bénéficiaire', value: user.name),
        ConfirmRow(label: 'Téléphone', value: user.maskedPhone),
        ConfirmRow(label: 'Montant', value: Money.format(amount, _currency), bold: true, valueColor: const Color(0xFFD4A843)),
        ConfirmRow(label: 'Motif', value: reason),
      ],
    );
    if (!confirmed || !mounted) return;

    setState(() => _submitting = true);
    try {
      await ref.read(walletRepositoryProvider).transfer(
        receiverPhone: user.phone,
        amount: amount,
        description: reason,
      );
      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SendMoneySuccessScreen(
            phone: user.phone,
            name: user.name,
            amount: amount,
            currency: _currency,
            reason: reason,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) { setState(() => _submitting = false); _toast(e.message); }
    } catch (_) {
      if (mounted) { setState(() => _submitting = false); _toast('Transfert impossible pour le moment.'); }
    }
  }

  Future<void> _openKycFlow() async {
    final route = _kycAccess.status == 'en_attente'
        ? MaterialPageRoute(builder: (_) => const KycStatusScreen())
        : MaterialPageRoute(builder: (_) => const RegisterScreen(resumeKyc: true));
    await Navigator.push(context, route);
    if (!mounted) return;
    await _loadKycAccess();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;

    return Scaffold(
      backgroundColor: palette.shellBottom,
      appBar: MbongoSubAppBar(title: "Envoi d'Argent"),
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
                child: MbongoMoneyParticles(color: palette.accent, count: 14, opacity: 0.08, height: 0),
              ),
            ),
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (!_kycAccess.allowed) ...[
                    KycActionBanner(
                      status: _kycAccess.status,
                      message: _kycAccess.message,
                      actionLabel: _kycAccess.status == 'en_attente' ? 'Voir le suivi KYC' : 'Compléter le dossier',
                      onAction: _openKycFlow,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ── Phase 1 : recherche ──────────────────────────────────
                  _buildSearchSection(palette),

                  // ── Phase 2 : montant (visible uniquement si bénéficiaire sélectionné) ──
                  if (_phase == 1) ...[
                    const SizedBox(height: 16),
                    _buildAmountSection(palette),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: _submitting || !_kycAccess.allowed ? null : _submit,
                      style: ElevatedButton.styleFrom(backgroundColor: palette.accentStrong),
                      child: _submitting
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                          : const Text('Valider le transfert'),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bloc de recherche ────────────────────────────────────────────────────
  Widget _buildSearchSection(MbongoThemePalette palette) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_search_rounded, color: palette.accent),
              const SizedBox(width: 8),
              const Text('Bénéficiaire', style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 14),

          // Carte bénéficiaire sélectionné ou champ de recherche
          if (_selected != null)
            _SelectedUserCard(user: _selected!, palette: palette, onClear: _clearSelection)
          else ...[
            TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              autofocus: false,
              decoration: InputDecoration(
                labelText: 'Nom ou numéro de téléphone',
                hintText: 'Ex: Rossy Mundyo ou +243…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : _searchCtrl.text.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.close_rounded), onPressed: () { _searchCtrl.clear(); setState(() { _results = []; }); })
                        : null,
              ),
            ),
            if (_searchError.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_searchError, style: const TextStyle(color: AppColors.red, fontSize: 12)),
            ],
            if (_results.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...(_results.map((u) => _UserResultTile(user: u, palette: palette, onTap: () => _selectUser(u)))),
            ] else if (!_searching && _searchCtrl.text.trim().length >= 2 && _results.isEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: palette.panel,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppColors.muted, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text('Aucun compte MBONGO trouvé. Vérifiez le nom ou le numéro.', style: TextStyle(color: AppColors.textSoft, fontSize: 12.5)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ── Bloc montant ─────────────────────────────────────────────────────────
  Widget _buildAmountSection(MbongoThemePalette palette) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payments_outlined, color: palette.accent),
              const SizedBox(width: 8),
              const Text('Détails du transfert', style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _currency,
            dropdownColor: palette.panelAlt,
            style: const TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              labelText: 'Devise',
              prefixIcon: Icon(Icons.currency_exchange_rounded, color: palette.accent),
            ),
            items: const [
              DropdownMenuItem(value: 'CDF', child: Text('CDF')),
              DropdownMenuItem(value: 'USD', child: Text('USD')),
            ],
            onChanged: (v) { if (v != null) setState(() => _currency = v); },
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Montant',
              hintText: '0,00',
              prefixIcon: Icon(Icons.account_balance_wallet_outlined, color: palette.accent),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _reasonCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Motif (optionnel)',
              hintText: 'Ex: Assistance familiale',
              prefixIcon: Icon(Icons.edit_note_outlined, color: palette.accent),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Widgets privés
// ─────────────────────────────────────────────────────────

class _SelectedUserCard extends StatelessWidget {
  final _MbongoUser user;
  final MbongoThemePalette palette;
  final VoidCallback onClear;
  const _SelectedUserCard({required this.user, required this.palette, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.accent.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          _Avatar(initials: user.initials, color: palette.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: const TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(user.maskedPhone, style: const TextStyle(color: AppColors.textSoft, fontSize: 12.5)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: const Text('MBONGO', style: TextStyle(color: AppColors.green, fontSize: 10, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.muted, size: 18), onPressed: onClear),
        ],
      ),
    );
  }
}

class _UserResultTile extends StatelessWidget {
  final _MbongoUser user;
  final MbongoThemePalette palette;
  final VoidCallback onTap;
  const _UserResultTile({required this.user, required this.palette, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: palette.panel,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                _Avatar(initials: user.initials, color: palette.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w800, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(user.maskedPhone, style: const TextStyle(color: AppColors.textSoft, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  final Color color;
  const _Avatar({required this.initials, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42, height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      alignment: Alignment.center,
      child: Text(initials, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w900)),
    );
  }
}
