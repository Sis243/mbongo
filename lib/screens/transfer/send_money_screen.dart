import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/dio_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../features/wallet/data/wallet_repository.dart';
import '../../services/kyc_guard_service.dart';
import '../../widgets/common/kyc_action_banner.dart';
import '../../widgets/common/mbongo_money_particles.dart';
import '../profile/kyc_status_screen.dart';
import '../register_screen.dart';
import 'send_money_success_screen.dart';
import '../../widgets/common/mbongo_sub_app_bar.dart';
import '../../widgets/common/transaction_confirm_sheet.dart';

class SendMoneyScreen extends ConsumerStatefulWidget {
  const SendMoneyScreen({super.key});

  @override
  ConsumerState<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends ConsumerState<SendMoneyScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();

  String selectedCurrency = 'CDF';
  bool isLoading = false;
  KycAccess _kycAccess = const KycAccess(
    allowed: false,
    status: 'non_commence',
    message: 'Verification en cours...',
  );

  @override
  void initState() {
    super.initState();
    _loadKycAccess();
  }

  Future<void> _loadKycAccess() async {
    final access = await KycGuardService.sensitiveOperationAccess();
    if (mounted == false) return;
    setState(() => _kycAccess = access);
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    amountController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  double _parseAmount(String value) {
    final normalized = value.replaceAll(',', '.').trim();
    return double.tryParse(normalized) ?? 0;
  }

  Future<void> _submit() async {
    if (_kycAccess.allowed == false) {
      _toast(_kycAccess.message);
      return;
    }

    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (isFormValid == false) return;

    final amount = _parseAmount(amountController.text);

    if (amount <= 0) {
      _toast("Veuillez saisir un montant valide.");
      return;
    }

    final confirmed = await showTransactionConfirmSheet(
      context: context,
      title: "Envoi d'argent",
      icon: Icons.send_rounded,
      rows: [
        ConfirmRow(label: 'Bénéficiaire', value: nameController.text.trim()),
        ConfirmRow(label: 'Téléphone', value: phoneController.text.trim()),
        ConfirmRow(label: 'Montant', value: '${amountController.text.trim()} $selectedCurrency', bold: true, valueColor: const Color(0xFFD4A843)),
        ConfirmRow(label: 'Motif', value: reasonController.text.trim().isEmpty ? "Transfert d'argent" : reasonController.text.trim()),
      ],
    );
    if (!mounted || !confirmed) return;

    setState(() => isLoading = true);
    try {
      await ref.read(walletRepositoryProvider).transfer(
            receiverPhone: phoneController.text.trim(),
            amount: amount,
            description: reasonController.text.trim().isEmpty
                ? "Transfert d'argent"
                : reasonController.text.trim(),
          );

      if (mounted == false) return;
      setState(() => isLoading = false);

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SendMoneySuccessScreen(
            phone: phoneController.text.trim(),
            name: nameController.text.trim(),
            amount: amount,
            currency: selectedCurrency,
            reason: reasonController.text.trim(),
          ),
        ),
      );
    } on ApiException catch (error) {
      if (mounted == false) return;
      setState(() => isLoading = false);
      _toast(error.message);
    } catch (_) {
      if (mounted == false) return;
      setState(() => isLoading = false);
      _toast("Transfert impossible pour le moment.");
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
        : MaterialPageRoute(builder: (_) => const RegisterScreen(resumeKyc: true));

    await Navigator.push(context, route);
    if (mounted == false) return;
    await _loadKycAccess();
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
                child: MbongoMoneyParticles(
                  color: palette.accent,
                  count: 14,
                  opacity: 0.08,
                  height: 0,
                ),
              ),
            ),
            SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_kycAccess.allowed == false) ...[
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
                    _buildHeaderCard(palette),
                    const SizedBox(height: 18),
                    _buildSectionCard(
                      title: "Beneficiaire",
                      icon: Icons.person_outline_rounded,
                      palette: palette,
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: nameController,
                            label: "Nom complet",
                            hint: "Ex: Jean Mukendi",
                            icon: Icons.badge_outlined,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Veuillez renseigner le nom.";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _buildTextField(
                            controller: phoneController,
                            label: "Telephone",
                            hint: "+243 XXX XXX XXX",
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Veuillez renseigner le numero.";
                              }
                              if (value.trim().length < 8) {
                                return "Numero invalide.";
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: "Details du transfert",
                      icon: Icons.payments_outlined,
                      palette: palette,
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: selectedCurrency,
                            dropdownColor: palette.panelAlt,
                            style: const TextStyle(
                              color: AppColors.darkText,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: InputDecoration(
                              labelText: "Devise",
                              prefixIcon: Icon(
                                Icons.currency_exchange_rounded,
                                color: palette.accent,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'CDF', child: Text('CDF')),
                              DropdownMenuItem(value: 'USD', child: Text('USD')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => selectedCurrency = value);
                              }
                            },
                          ),
                          const SizedBox(height: 14),
                          _buildTextField(
                            controller: amountController,
                            label: "Montant",
                            hint: "Ex: 10000",
                            icon: Icons.account_balance_wallet_outlined,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Veuillez renseigner le montant.";
                              }
                              final amount = _parseAmount(value);
                              if (amount <= 0) {
                                return "Montant invalide.";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _buildTextField(
                            controller: reasonController,
                            label: "Motif",
                            hint: "Ex: Assistance familiale",
                            icon: Icons.edit_note_outlined,
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Veuillez renseigner le motif.";
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: isLoading || (_kycAccess.allowed == false) ? null : _submit,
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
                          : const Text("Valider le transfert"),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoBox(
                      icon: Icons.shield_outlined,
                      palette: palette,
                      text:
                          "Les operations MBONGO sont traitees dans un environnement securise conforme aux standards bancaires.",
                    ),
                  ],
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
              Icon(Icons.account_balance_rounded, color: palette.accentStrong),
              const SizedBox(width: 8),
              const Text(
                "MBONGO",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "Envoyer de l'argent",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Envoyez de l'argent instantanement a tout compte MBONGO actif. Saisissez le telephone du beneficiaire, la devise, le montant et le motif. Un KYC valide est requis pour les montants eleves.",
            style: TextStyle(
              color: Color(0xFFE8EEF8),
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
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

  Widget _buildInfoBox({
    required IconData icon,
    required MbongoThemePalette palette,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.accent.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Icon(icon, color: palette.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(
        color: AppColors.text,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: MbongoThemeController.current.panel,
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.muted),
        labelStyle: const TextStyle(color: AppColors.muted),
        prefixIcon: Icon(icon, color: MbongoThemeController.current.accent),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: AppColors.border.withValues(alpha: 0.24),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: MbongoThemeController.current.accent,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}
