import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../services/profile_persistence_service.dart';
import '../../widgets/common/app_scaffold.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final currentPinController = TextEditingController();
  final newPinController = TextEditingController();
  final confirmPinController = TextEditingController();

  bool obscure1 = true;
  bool obscure2 = true;
  bool obscure3 = true;
  bool isSaving = false;

  @override
  void dispose() {
    currentPinController.dispose();
    newPinController.dispose();
    confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final currentPin = currentPinController.text.trim();
    final newPin = newPinController.text.trim();
    final confirmPin = confirmPinController.text.trim();

    if (currentPin.isEmpty || newPin.isEmpty || confirmPin.isEmpty) {
      _toast('Veuillez remplir tous les champs.');
      return;
    }

    if (newPin.length < 4) {
      _toast('Le nouveau code PIN doit contenir au moins 4 chiffres.');
      return;
    }

    if (newPin != confirmPin) {
      _toast('La confirmation du code PIN ne correspond pas.');
      return;
    }

    setState(() => isSaving = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await ProfilePersistenceService.savePinConfigured(true);

    if (!mounted) return;
    setState(() => isSaving = false);
    _toast('Code PIN mis a jour.');
    Navigator.pop(context);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    return MbongoPageScaffold(
      title: 'Code PIN',
      primaryParticleColor: palette.accentStrong,
      secondaryParticleColor: palette.accent,
      child: ListView(
        children: [
          _header(),
          const SizedBox(height: 18),
          _stepBoard(),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.panelAlt,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.24),
              ),
            ),
            child: Column(
              children: [
                _field(
                  controller: currentPinController,
                  label: 'Code PIN actuel',
                  obscure: obscure1,
                  onToggle: () => setState(() => obscure1 = !obscure1),
                ),
                const SizedBox(height: 10),
                _field(
                  controller: newPinController,
                  label: 'Nouveau code PIN',
                  obscure: obscure2,
                  onToggle: () => setState(() => obscure2 = !obscure2),
                ),
                const SizedBox(height: 10),
                _field(
                  controller: confirmPinController,
                  label: 'Confirmation du PIN',
                  obscure: obscure3,
                  onToggle: () => setState(() => obscure3 = !obscure3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _securityHint(),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: isSaving ? null : _submit,
            child: isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : const Text('Mettre a jour'),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    final palette = MbongoThemeController.current;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette.bannerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Code PIN',
            style: TextStyle(
              color: palette.accentStrong,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Rotation du secret',
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Mettez a jour le code d acces principal du profil.',
            style: const TextStyle(
              color: AppColors.textSoft,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepBoard() {
    final palette = MbongoThemeController.current;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.24),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Parcours',
            style: TextStyle(
              color: AppColors.darkText,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '1. Verifier le PIN actuel\n2. Definir un nouveau secret\n3. Confirmer le nouveau code',
            style: TextStyle(
              color: AppColors.darkMuted,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _securityHint() {
    final palette = MbongoThemeController.current;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            palette.accent.withValues(alpha: 0.12),
            palette.accentStrong.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: palette.accent.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.shield_moon_rounded,
            color: palette.accent,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conseil securite',
                  style: TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Evitez les suites simples et utilisez un code different de celui de votre appareil ou de votre carte.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12.6,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    final palette = MbongoThemeController.current;
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: TextInputType.number,
      style: const TextStyle(
        color: AppColors.text,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: palette.panel,
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.muted),
        prefixIcon: Icon(
          Icons.lock_outline_rounded,
          color: palette.accent,
        ),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          ),
        ),
      ),
    );
  }
}
