import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../features/wallet/data/wallet_repository.dart';
import '../../services/kyc_guard_service.dart';
import '../../widgets/common/kyc_action_banner.dart';
import '../../widgets/common/mbongo_money_particles.dart';
import '../profile/kyc_status_screen.dart';
import '../register_screen.dart';
import '../../widgets/common/mbongo_sub_app_bar.dart';

class TransferInternationalScreen extends ConsumerStatefulWidget {
  const TransferInternationalScreen({super.key});

  @override
  ConsumerState<TransferInternationalScreen> createState() =>
      _TransferInternationalScreenState();
}

class _TransferInternationalScreenState
    extends ConsumerState<TransferInternationalScreen> {
  final _formKey = GlobalKey<FormState>();

  final beneficiaryController = TextEditingController();
  final countryController = TextEditingController();
  final amountController = TextEditingController();
  final reasonController = TextEditingController();
  bool _submitting = false;
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
    if (!mounted) return;
    setState(() => _kycAccess = access);
  }

  @override
  void dispose() {
    beneficiaryController.dispose();
    countryController.dispose();
    amountController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  Future<void> _openKycFlow() async {
    final route = _kycAccess.status == 'en_attente'
        ? MaterialPageRoute(builder: (_) => const KycStatusScreen())
        : MaterialPageRoute(builder: (_) => const RegisterScreen(resumeKyc: true));

    await Navigator.push(context, route);
    if (!mounted) return;
    await _loadKycAccess();
  }

  Future<void> _submit() async {
    if (!_kycAccess.allowed) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_kycAccess.message)));
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(amountController.text.trim().replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Montant invalide.')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(walletRepositoryProvider).transferInternational(
            beneficiary: beneficiaryController.text.trim(),
            country: countryController.text.trim(),
            amount: amount,
            reason: reasonController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.green,
          content: Text('Demande de transfert international enregistree. En attente de traitement.'),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;

    return Scaffold(
      backgroundColor: palette.shellBottom,
      appBar: MbongoSubAppBar(title: 'Transfert International'),
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
                color: palette.accentStrong,
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
                  _hero(palette),
                  const SizedBox(height: 18),
                  _sectionCard(
                    palette: palette,
                    title: 'Informations du transfert',
                    icon: Icons.public_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: beneficiaryController,
                          decoration: _decoration(
                            'Nom du beneficiaire',
                            'Ex: John Smith',
                            Icons.person_outline,
                            palette,
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? "Champ obligatoire" : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: countryController,
                          decoration: _decoration(
                            'Pays de destination',
                            'Ex: France',
                            Icons.flag_outlined,
                            palette,
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? "Champ obligatoire" : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: _decoration(
                            'Montant',
                            'Ex: 250',
                            Icons.payments_outlined,
                            palette,
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? "Champ obligatoire" : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: reasonController,
                          maxLines: 3,
                          decoration: _decoration(
                            'Motif',
                            'Ex: Assistance familiale',
                            Icons.edit_note_outlined,
                            palette,
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? "Champ obligatoire" : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: palette.accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: palette.accent.withValues(alpha: 0.24)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.shield_outlined, color: palette.accent),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            "Le transfert international reste soumis a la verification KYC et au controle de conformite.",
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              height: 1.4,
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
                      child: Text(_submitting ? "Envoi en cours..." : "Proceder"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero(MbongoThemePalette palette) {
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
              Icon(Icons.public, color: palette.accentStrong, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Envoyez vers l'international",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            "Initiez un virement vers l'etranger depuis votre portefeuille MBONGO. La conformite KYC et le controle de devises sont appliques automatiquement selon le montant et le pays de destination.",
            style: TextStyle(
              color: Color(0xFFE8EEF8),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required MbongoThemePalette palette,
    required String title,
    required IconData icon,
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

  InputDecoration _decoration(
    String label,
    String hint,
    IconData icon,
    MbongoThemePalette palette,
  ) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: palette.accent),
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
}
