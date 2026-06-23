import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../features/auth/presentation/auth_notifier.dart';
import '../../features/cards/presentation/card_notifier.dart';
import '../../services/kyc_guard_service.dart';
import '../../widgets/cards/virtual_bank_card.dart';
import '../../widgets/common/kyc_action_banner.dart';
import '../../widgets/common/mbongo_money_particles.dart';
import '../profile/kyc_status_screen.dart';
import '../register_screen.dart';
import '../../widgets/common/mbongo_sub_app_bar.dart';

class CreateVirtualCardScreen extends ConsumerStatefulWidget {
  const CreateVirtualCardScreen({super.key});

  @override
  ConsumerState<CreateVirtualCardScreen> createState() => _CreateVirtualCardScreenState();
}

class _CreateVirtualCardScreenState extends ConsumerState<CreateVirtualCardScreen> {
  String selectedCurrency = 'USD';
  String selectedBrand = 'VISA';
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
    if (!mounted) return;
    setState(() => _kycAccess = access);
  }

  Future<void> _submit() async {
    if (!_kycAccess.allowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_kycAccess.message)),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final holderName =
          ref.read(authProvider).valueOrNull?.name ?? 'Client MBONGO';
      await ref.read(cardProvider.notifier).createCard(
            holderName: holderName,
            currency: selectedCurrency,
            brand: selectedBrand,
          );
    } catch (error) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
      return;
    }

    if (!mounted) return;
    setState(() => isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Carte virtuelle creee.')),
    );
    Navigator.pop(context);
  }

  Future<void> _openKycFlow() async {
    final route = _kycAccess.status == 'en_attente'
        ? MaterialPageRoute(builder: (_) => const KycStatusScreen())
        : MaterialPageRoute(builder: (_) => const RegisterScreen(resumeKyc: true));

    await Navigator.push(context, route);
    if (!mounted) return;
    await _loadKycAccess();
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: MbongoSubAppBar(title: 'Nouvelle carte'),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: MbongoMoneyParticles(
                color: MbongoThemeController.current.accent,
                count: 12,
                opacity: 0.08,
                height: 0,
              ),
            ),
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
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
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      MbongoThemeController.current.bannerGradient.first.withValues(
                        alpha: 0.95,
                      ),
                      MbongoThemeController.current.bannerGradient.last.withValues(
                        alpha: 0.95,
                      ),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.75)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Carte protegee',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'VISA / Mastercard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Carte virtuelle MBONGO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Creez une carte USD ou CDF en VISA ou Mastercard. Utilisable pour vos paiements en ligne, abonnements et achats internationaux. Rechargez, bloquez ou consultez les details a tout moment.',
                      style: TextStyle(
                        color: Color(0xFFE8EEF8),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Row(
                      children: [
                        Expanded(child: _CreateFeature(label: 'Web', value: 'Pret')),
                        SizedBox(width: 8),
                        Expanded(child: _CreateFeature(label: 'KYC', value: 'Requis')),
                        SizedBox(width: 8),
                        Expanded(child: _CreateFeature(label: 'Blocage', value: 'Instant')),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              VirtualBankCard(
                brand: selectedBrand,
                holderName: ref.read(authProvider).valueOrNull?.name ?? 'Client MBONGO',
                maskedPan: selectedBrand == 'MASTERCARD'
                    ? '5210 **** **** 5678'
                    : '4111 **** **** 1234',
                currency: selectedCurrency,
                status: 'ACTIVE',
                expiry: '08/29',
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: palette.panelAlt,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.24),
                  ),
                ),
                child: Column(
                  children: [
                    _infoRow('Porteur', ref.read(authProvider).valueOrNull?.name ?? 'Client MBONGO'),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCurrency,
                      dropdownColor: palette.panelAlt,
                      style: const TextStyle(
                        color: AppColors.darkText,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Devise',
                        prefixIcon: Icon(Icons.currency_exchange_rounded),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'USD', child: Text('USD')),
                        DropdownMenuItem(value: 'CDF', child: Text('CDF')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedCurrency = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedBrand,
                      dropdownColor: palette.panelAlt,
                      style: const TextStyle(
                        color: AppColors.darkText,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Reseau',
                        prefixIcon: Icon(Icons.verified_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'VISA', child: Text('VISA')),
                        DropdownMenuItem(value: 'MASTERCARD', child: Text('Mastercard')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedBrand = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: palette.panelAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.24),
                  ),
                ),
                  child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Activation',
                      style: TextStyle(
                        color: AppColors.darkText,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'La carte est activee immediatement. Les recharges sont debitees de votre portefeuille MBONGO et visibles dans votre journal de transactions.',
                      style: TextStyle(
                        color: AppColors.darkMuted,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading || !_kycAccess.allowed ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : const Text('Activer la carte'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    final palette = MbongoThemeController.current;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.darkMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.darkText,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateFeature extends StatelessWidget {
  final String label;
  final String value;

  const _CreateFeature({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFE8EEF8),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
