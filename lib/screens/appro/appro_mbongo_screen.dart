import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/dio_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../core/utils/money.dart';
import '../../features/wallet/presentation/wallet_notifier.dart';
import '../../models/cash_agent_option.dart';
import '../../widgets/common/mbongo_money_particles.dart';
import '../../widgets/common/mbongo_sub_app_bar.dart';

class ApproMbongoScreen extends ConsumerStatefulWidget {
  final String? prefilledAgentPhone;
  final String? prefilledAgentName;
  final String? initialSource;
  const ApproMbongoScreen({super.key, this.prefilledAgentPhone, this.prefilledAgentName, this.initialSource});

  @override
  ConsumerState<ApproMbongoScreen> createState() => _ApproMbongoScreenState();
}

class _ApproMbongoScreenState extends ConsumerState<ApproMbongoScreen> {
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  final phoneController = TextEditingController();
  List<CashAgentOption> _cashAgents = [];
  CashAgentOption? _selectedCashAgent;
  bool _loadingCashAgents = false;
  bool _submitting = false;
  String _cashAgentError = '';

  String selectedSource = 'Compte bancaire';
  String selectedWallet = 'Portefeuille CDF';

  final List<String> sources = [
    'Compte bancaire',
    'Carte bancaire',
    'Mobile Money',
    'Agent cash',
  ];

  final List<String> wallets = [
    'Portefeuille CDF',
    'Portefeuille USD',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialSource != null) {
      selectedSource = widget.initialSource!;
    }
    _loadCashAgents().then((_) {
      if (!mounted) return;
      if (widget.prefilledAgentPhone != null) {
        final match = _cashAgents.where((a) => a.phone == widget.prefilledAgentPhone).firstOrNull;
        if (match != null) setState(() { _selectedCashAgent = match; selectedSource = 'Agent cash'; });
      }
    });
  }

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadCashAgents() async {
    setState(() {
      _loadingCashAgents = true;
      _cashAgentError = '';
    });

    try {
      final resp = await ref.read(dioClientProvider).get('/transactions/cash-agents');
      final list = resp['data'];
      final raw = (list is List)
          ? list.map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : <Map<String, dynamic>>[];
      final agents = raw
          .map(CashAgentOption.fromJson)
          .where((agent) => agent.id.isNotEmpty && agent.name.isNotEmpty)
          .toList();

      if (!mounted) return;
      setState(() {
        _cashAgents = agents;
        _selectedCashAgent = agents.isEmpty ? null : agents.first;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _cashAgentError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loadingCashAgents = false);
      }
    }
  }

  Future<void> _submit() async {
    final amount =
        double.tryParse(amountController.text.trim().replaceAll(',', '.'));

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez renseigner un montant valide.')),
      );
      return;
    }

    if (selectedSource == 'Mobile Money' &&
        phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez renseigner le numero Mobile Money.')),
      );
      return;
    }

    if (selectedSource == 'Agent cash' && _selectedCashAgent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez choisir un agent cash actif.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final client = ref.read(dioClientProvider);
      await client.post('/transactions/deposit', {
        'amount': amount,
        'source': selectedSource,
        if (noteController.text.trim().isNotEmpty)
          'description': noteController.text.trim(),
        if (_selectedCashAgent != null) 'agentId': _selectedCashAgent!.id,
        if (_selectedCashAgent != null) 'agentName': _selectedCashAgent!.name,
      });

      ref.refresh(walletProvider.future).ignore();

      if (!mounted) return;
      amountController.clear();
      noteController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Depot enregistre : ${Money.format(amount, 'CDF')}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;

    return Scaffold(
      backgroundColor: palette.shellBottom,
      appBar: MbongoSubAppBar(title: 'Depot MBONGO'),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [palette.shellTop, palette.shellBottom],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: MbongoMoneyParticles(
                color: palette.accent,
                count: 19,
                opacity: 0.11,
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _header(palette),
                const SizedBox(height: 18),
                _sectionCard(
                  title: "Source du depot",
                  icon: Icons.account_balance_wallet_rounded,
                  palette: palette,
                  child: Column(
                    children: [
                      _choiceWrap(
                        options: sources,
                        selected: selectedSource,
                        palette: palette,
                        onSelect: (value) =>
                            setState(() => selectedSource = value),
                      ),
                      const SizedBox(height: 14),
                      _choiceWrap(
                        options: wallets,
                        selected: selectedWallet,
                        palette: palette,
                        onSelect: (value) =>
                            setState(() => selectedWallet = value),
                      ),
                      if (selectedSource == 'Mobile Money') ...[
                        const SizedBox(height: 14),
                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: _inputDecoration(
                            'Numero Mobile Money',
                            Icon(
                              Icons.phone_android_rounded,
                              color: palette.accent,
                            ),
                            palette,
                            hint: '+243 XXX XXX XXX',
                          ),
                        ),
                      ],
                      if (selectedSource == 'Agent cash') ...[
                        const SizedBox(height: 14),
                        _buildCashAgentSelector(palette),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _sectionCard(
                  title: 'Details',
                  icon: Icons.payments_outlined,
                  palette: palette,
                  child: Column(
                    children: [
                      TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: const TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: _inputDecoration(
                          'Montant',
                          Icon(
                            Icons.monetization_on_outlined,
                            color: palette.accentStrong,
                          ),
                          palette,
                          hint: 'Ex: 50000',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: noteController,
                        maxLines: 3,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: _inputDecoration(
                          'Note',
                          Icon(Icons.edit_note_rounded, color: palette.accent),
                          palette,
                          hint: 'Motif ou commentaire',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
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
                    children: [
                      Icon(Icons.info_outline, color: palette.accent),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Rechargez votre portefeuille MBONGO via Mobile Money, carte bancaire ou agent cash.',
                          style: TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
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
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.accentStrong,
                    ),
                    child: Text(_submitting
                        ? 'Traitement...'
                        : "Valider l'approvisionnement"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashAgentSelector(MbongoThemePalette palette) {
    if (_loadingCashAgents) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.panel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: palette.accent,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Chargement des agents cash...',
                style: TextStyle(
                  color: AppColors.darkMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_cashAgents.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.panel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
        ),
        child: Row(
          children: [
            Icon(Icons.account_balance_outlined, color: palette.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _cashAgentError.isEmpty
                    ? 'Aucun agent cash actif disponible.'
                    : _cashAgentError,
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
            TextButton(
              onPressed: _loadCashAgents,
              child: const Text('Recharger'),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<CashAgentOption>(
      initialValue: _selectedCashAgent,
      items: _cashAgents
          .map(
            (agent) => DropdownMenuItem(
              value: agent,
              child: Text(
                agent.label,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (agent) => setState(() => _selectedCashAgent = agent),
      decoration: _inputDecoration(
        'Agent cash',
        Icon(Icons.account_balance_outlined, color: palette.accent),
        palette,
        hint: _selectedCashAgent == null
            ? null
            : 'Plafond entree: ${Money.format(_selectedCashAgent!.dailyCashInLimit, 'CDF')}',
      ),
    );
  }

  Widget _header(MbongoThemePalette palette) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette.bannerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.24),
        ),
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
              Icon(Icons.account_balance_wallet_rounded,
                  color: palette.accentStrong),
              const SizedBox(width: 8),
              const Text(
                'Depot MBONGO',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Alimentez votre portefeuille',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Deposez des fonds en CDF via compte bancaire, carte, Mobile Money ou agent cash CADECO agree. Le credit est disponible immediatement apres confirmation de la source choisie.',
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

  Widget _sectionCard({
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

  InputDecoration _inputDecoration(
    String label,
    Widget prefix,
    MbongoThemePalette palette, {
    String? hint,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: palette.panel,
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: AppColors.muted),
      hintStyle: const TextStyle(color: AppColors.muted),
      prefixIcon: prefix,
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
    );
  }

  Widget _choiceWrap({
    required List<String> options,
    required String selected,
    required MbongoThemePalette palette,
    required ValueChanged<String> onSelect,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((option) {
        final active = option == selected;
        return GestureDetector(
          onTap: () => onSelect(option),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: active ? const Color(0xFF102A55) : palette.panel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active
                    ? palette.accent
                    : AppColors.border.withValues(alpha: 0.24),
              ),
            ),
            child: Text(
              option,
              style: TextStyle(
                color: active ? Colors.white : AppColors.text,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
