import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/dio_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../core/utils/money.dart';
import '../../features/wallet/data/wallet_repository.dart';
import '../../features/wallet/presentation/wallet_notifier.dart';
import '../../models/account_model.dart';
import '../../models/cash_agent_option.dart';
import '../../services/kyc_guard_service.dart';
import '../../widgets/cards/wallet_card.dart';
import '../../widgets/common/kyc_action_banner.dart';
import '../../widgets/common/mbongo_money_particles.dart';
import '../profile/kyc_status_screen.dart';
import '../register_screen.dart';
import 'withdraw_success_screen.dart';
import '../../widgets/common/mbongo_sub_app_bar.dart';

class WithdrawScreen extends ConsumerStatefulWidget {
  const WithdrawScreen({super.key});

  @override
  ConsumerState<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends ConsumerState<WithdrawScreen> {
  int modeIndex = 0;

  final amountController = TextEditingController();
  final phoneController = TextEditingController();
  List<CashAgentOption> _cashAgents = [];
  CashAgentOption? _selectedCashAgent;
  bool _loadingCashAgents = false;
  String _cashAgentError = '';
  KycAccess _kycAccess = const KycAccess(
    allowed: false,
    status: 'non_commence',
    message: 'Verification en cours...',
  );

  final List<String> modes = [
    "M-Pesa",
    "Orange Money",
    "Airtel Money",
    "AfriMoney",
    "Guichet",
    "DAB",
  ];

  @override
  void initState() {
    super.initState();
    _loadKycAccess();
    _loadCashAgents();
  }

  Future<void> _loadKycAccess() async {
    final access = await KycGuardService.sensitiveOperationAccess();
    if (!mounted) return;
    setState(() => _kycAccess = access);
  }

  @override
  void dispose() {
    amountController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  bool get _isMobileMoney =>
      modes[modeIndex] == "M-Pesa" ||
      modes[modeIndex] == "Orange Money" ||
      modes[modeIndex] == "Airtel Money" ||
      modes[modeIndex] == "AfriMoney";

  String get _mobileLabel {
    switch (modes[modeIndex]) {
      case "M-Pesa":
        return "Numero M-Pesa";
      case "Orange Money":
        return "Numero Orange Money";
      case "Airtel Money":
        return "Numero Airtel Money";
      case "AfriMoney":
        return "Numero AfriMoney";
      default:
        return "Numero";
    }
  }

  String _generateReference() {
    final random = Random();
    return "WTH-${DateTime.now().millisecondsSinceEpoch}-${random.nextInt(9999).toString().padLeft(4, '0')}";
  }

  Future<void> _loadCashAgents() async {
    setState(() {
      _loadingCashAgents = true;
      _cashAgentError = '';
    });

    try {
      final response = await ref.read(walletRepositoryProvider).fetchCashAgents();
      final agents = response
          .map(CashAgentOption.fromJson)
          .where((agent) => agent.id.isNotEmpty && agent.name.isNotEmpty)
          .toList();

      if (!mounted) return;
      setState(() {
        _cashAgents = agents;
        _selectedCashAgent = agents.isEmpty ? null : agents.first;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _cashAgentError = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _cashAgentError = 'Agents cash indisponibles.');
    } finally {
      if (mounted) {
        setState(() => _loadingCashAgents = false);
      }
    }
  }

  Future<void> submit() async {
    if (!_kycAccess.allowed) {
      _toast(_kycAccess.message);
      return;
    }

    final walletData = ref.read(walletProvider).valueOrNull;
    final currency = walletData?.currency ?? 'CDF';
    final amount =
        double.tryParse(amountController.text.trim().replaceAll(",", "."));

    if (amount == null || amount <= 0) {
      _toast("Veuillez entrer un montant valide.");
      return;
    }

    if (_isMobileMoney && phoneController.text.trim().isEmpty) {
      _toast("Veuillez renseigner le numero Mobile Money.");
      return;
    }

    if (modes[modeIndex] == "Guichet" && _selectedCashAgent == null) {
      _toast("Veuillez choisir un agent cash actif.");
      return;
    }

    final reference = _generateReference();
    try {
      await ref.read(walletRepositoryProvider).withdraw(
            amount: amount,
            channel: modes[modeIndex],
            reference: reference,
            phone: phoneController.text.trim().isEmpty
                ? null
                : phoneController.text.trim(),
            agentId: _selectedCashAgent?.id,
          );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WithdrawSuccessScreen(
            mode: modes[modeIndex],
            currency: currency,
            amount: amount,
            reference: reference,
            phone: phoneController.text.trim(),
            agentName: _selectedCashAgent?.label ?? '',
          ),
        ),
      );
    } on ApiException catch (error) {
      _toast(error.message);
    } catch (_) {
      _toast("Retrait impossible pour le moment.");
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openKycFlow() async {
    final route = _kycAccess.status == 'en_attente'
        ? MaterialPageRoute(builder: (_) => const KycStatusScreen())
        : MaterialPageRoute(
            builder: (_) => const RegisterScreen(resumeKyc: true));

    await Navigator.push(context, route);
    if (!mounted) return;
    await _loadKycAccess();
  }

  Widget _buildCashAgentSelector(dynamic palette) {
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
                "Chargement des agents cash...",
                style: TextStyle(
                  color: AppColors.muted,
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
                    ? "Aucun agent cash actif disponible."
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
              child: const Text("Recharger"),
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
      decoration: InputDecoration(
        filled: true,
        fillColor: palette.panel,
        labelText: "Agent cash",
        helperText: _selectedCashAgent == null
            ? null
            : "Plafond sortie: ${Money.format(_selectedCashAgent!.dailyCashOutLimit, 'CDF')}",
        labelStyle: const TextStyle(color: AppColors.muted),
        helperStyle: const TextStyle(
          color: AppColors.muted,
          fontWeight: FontWeight.w700,
        ),
        prefixIcon: Icon(
          Icons.account_balance_outlined,
          color: palette.accent,
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
        : AccountModel(
            id: '',
            type: 'Portefeuille CDF',
            currency: 'CDF',
            number: 'MBONGO-CDF',
            balance: 0,
            selected: true,
          );

    return Scaffold(
      backgroundColor: palette.shellBottom,
      appBar: MbongoSubAppBar(title: 'Retrait'),
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
                  if (!_kycAccess.allowed) ...[
                    KycActionBanner(
                      status: _kycAccess.status,
                      message: _kycAccess.message,
                      actionLabel: _kycAccess.status == 'en_attente'
                          ? 'Voir le suivi KYC'
                          : 'Completer le dossier',
                      onAction: _openKycFlow,
                    ),
                    const SizedBox(height: 14),
                  ],
                  _buildHeaderCard(),
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
                    title: "Mode de retrait",
                    icon: Icons.payments_outlined,
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: List.generate(
                        modes.length,
                        (i) {
                          final selected = i == modeIndex;
                          return Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => setState(() => modeIndex = i),
                              child: Container(
                                width: 170,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? palette.accentStrong
                                      : palette.panelAlt,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: selected
                                        ? palette.accentStrong
                                        : AppColors.border,
                                  ),
                                ),
                                child: Text(
                                  modes[i],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : palette.accentStrong,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: "Informations du retrait",
                    icon: Icons.account_balance_wallet_outlined,
                    child: Column(
                      children: [
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
                            labelStyle:
                                const TextStyle(color: AppColors.muted),
                            hintStyle:
                                const TextStyle(color: AppColors.muted),
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
                        if (_isMobileMoney) ...[
                          const SizedBox(height: 14),
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
                              labelText: _mobileLabel,
                              hintText: "+243 XXX XXX XXX",
                              labelStyle:
                                  const TextStyle(color: AppColors.muted),
                              hintStyle:
                                  const TextStyle(color: AppColors.muted),
                              prefixIcon: Icon(
                                Icons.phone_android_rounded,
                                color: palette.accent,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                  color:
                                      AppColors.border.withValues(alpha: 0.24),
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
                        if (modes[modeIndex] == "Guichet") ...[
                          const SizedBox(height: 14),
                          _buildCashAgentSelector(palette),
                        ],
                        if (modes[modeIndex] == "DAB") ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: palette.panelAlt,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: palette.accent.withValues(alpha: 0.28),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.atm_rounded, color: palette.accent),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "Un code de retrait DAB sera genere apres validation.",
                                    style: TextStyle(
                                      color: AppColors.darkText,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.accentStrong,
                    ),
                    child: const Text("Valider le retrait"),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette.bannerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: palette.glow.withValues(alpha: 0.22),
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
              Icon(Icons.payments_rounded, color: palette.accentStrong),
              SizedBox(width: 8),
              Text(
                "Retrait de fonds",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            "Retirez en especes via Mobile Money (M-Pesa, Orange, Airtel, AfriMoney), guichet CADECO ou DAB. Saisissez le montant, choisissez le canal et presentez la reference generee. KYC requis.",
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
}
