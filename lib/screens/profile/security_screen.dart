import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';
import '../../services/profile_persistence_service.dart';
import '../../widgets/common/app_scaffold.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _loading = true;
  bool biometricEnabled = false;
  bool faceRecognitionEnabled = false;
  bool livenessCheckEnabled = true;
  bool palmRecognitionEnabled = false;
  bool nfcPaymentsEnabled = true;
  bool loginAlerts = true;
  bool selfieVerification = false;
  bool trustedDevice = true;
  String biometricLabel = 'Biometrie locale';

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    biometricEnabled = await AuthService.isBiometricEnabled();
    faceRecognitionEnabled = await AuthService.isFaceRecognitionEnabled();
    livenessCheckEnabled = await AuthService.isLivenessCheckEnabled();
    palmRecognitionEnabled = await AuthService.isPalmRecognitionEnabled();
    nfcPaymentsEnabled = await AuthService.isNfcPaymentsEnabled();
    selfieVerification = await AuthService.isProfilePhotoVerified();
    biometricLabel = await BiometricService.securityLabel();

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _setBiometric(bool value) async {
    setState(() => biometricEnabled = value);
    await AuthService.setBiometricEnabled(value);
  }

  Future<void> _setSelfieVerification(bool value) async {
    setState(() => selfieVerification = value);
    await ProfilePersistenceService.savePhotoVerified(value);
  }

  Future<void> _setFaceRecognition(bool value) async {
    setState(() => faceRecognitionEnabled = value);
    await AuthService.setFaceRecognitionEnabled(value);
  }

  Future<void> _setLivenessCheck(bool value) async {
    setState(() => livenessCheckEnabled = value);
    await AuthService.setLivenessCheckEnabled(value);
  }

  Future<void> _setPalmRecognition(bool value) async {
    setState(() => palmRecognitionEnabled = value);
    await AuthService.setPalmRecognitionEnabled(value);
  }

  Future<void> _setNfcPayments(bool value) async {
    setState(() => nfcPaymentsEnabled = value);
    await AuthService.setNfcPaymentsEnabled(value);
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    return MbongoPageScaffold(
      title: 'Securite',
      primaryParticleColor: palette.accentStrong,
      secondaryParticleColor: palette.accent,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _header(),
                const SizedBox(height: 18),
                _statusStrip(),
                const SizedBox(height: 18),
                _switchTile(
                  title: 'Biometrie',
                  subtitle: biometricLabel,
                  value: biometricEnabled,
                  onChanged: _setBiometric,
                ),
                const SizedBox(height: 10),
                _switchTile(
                  title: 'Reconnaissance faciale',
                  subtitle: 'Renforcer les connexions sensibles par le visage',
                  value: faceRecognitionEnabled,
                  onChanged: _setFaceRecognition,
                ),
                const SizedBox(height: 10),
                _switchTile(
                  title: 'Controle de presence',
                  subtitle: 'Verifier qu il s agit bien d une personne reelle',
                  value: livenessCheckEnabled,
                  onChanged: _setLivenessCheck,
                ),
                const SizedBox(height: 10),
                _switchTile(
                  title: 'Paiement NFC',
                  subtitle: 'Autoriser les reglements sans contact sur appareil compatible',
                  value: nfcPaymentsEnabled,
                  onChanged: _setNfcPayments,
                ),
                const SizedBox(height: 10),
                _switchTile(
                  title: 'Reconnaissance de la main',
                  subtitle: 'Preparer les validations paume pour usage marchand',
                  value: palmRecognitionEnabled,
                  onChanged: _setPalmRecognition,
                ),
                const SizedBox(height: 10),
                _switchTile(
                  title: 'Alertes de connexion',
                  subtitle: 'Surveiller les ouvertures inhabituelles',
                  value: loginAlerts,
                  onChanged: (value) => setState(() => loginAlerts = value),
                ),
                const SizedBox(height: 10),
                _switchTile(
                  title: 'Verification photo',
                  subtitle: 'Renforcer le profil client',
                  value: selfieVerification,
                  onChanged: _setSelfieVerification,
                ),
                const SizedBox(height: 10),
                _switchTile(
                  title: 'Appareil de confiance',
                  subtitle: 'Garder cet appareil autorise',
                  value: trustedDevice,
                  onChanged: (value) => setState(() => trustedDevice = value),
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
            'Securite',
            style: TextStyle(
              color: palette.accent,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Protection et preuves',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Protection du compte',
            style: TextStyle(
              color: palette.accentStrong,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusStrip() {
    return Row(
      children: [
        Expanded(
          child: _statusCell(
            'Biometrie',
            biometricEnabled ? biometricLabel : 'Inactive',
            biometricEnabled ? AppColors.green : AppColors.orange,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statusCell(
            'Verification',
            faceRecognitionEnabled ? 'Visage arme' : 'Standard',
            faceRecognitionEnabled ? AppColors.green : AppColors.orange,
          ),
        ),
      ],
    );
  }

  Widget _statusCell(String label, String value, Color color) {
    final palette = MbongoThemeController.current;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.darkMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.darkMuted,
                    fontSize: 12.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
