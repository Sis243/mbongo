import 'package:flutter/material.dart';

import '../../core/storage/app_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../services/api_service.dart';
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
  String? _backupPhone;
  bool _savingBackupPhone = false;

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
    final backup = await ApiService.getBackupPhone();

    if (!mounted) return;
    setState(() {
      _backupPhone = backup;
      _loading = false;
    });
  }

  Future<void> _setBiometric(bool value) async {
    if (value) {
      final available = await BiometricService.canCheck();
      if (!available) {
        if (mounted) {
          _toast('Biometrie non disponible sur cet appareil.');
        }
        return;
      }

      final pin = await _askPinDialog();
      if (pin == null || pin.isEmpty) return;

      final user = await AppStorage().getCurrentUser();
      final phone = user?['phone'] as String?;
      if (phone != null && phone.isNotEmpty) {
        await AppStorage().saveBioCredentials(phone, pin);
      }
    } else {
      await AppStorage().clearBioCredentials();
    }

    setState(() => biometricEnabled = value);
    await AuthService.setBiometricEnabled(value);
  }

  Future<String?> _askPinDialog() async {
    final ctrl = TextEditingController();
    final palette = MbongoThemeController.current;
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: palette.panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(Icons.fingerprint_rounded, color: palette.accent),
            const SizedBox(width: 10),
            const Text(
              'Activer la biometrie',
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Entrez votre code PIN pour enregistrer vos identifiants biometriques de facon securisee.',
              style: TextStyle(
                color: AppColors.textSoft,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Code PIN',
                prefixIcon: Icon(Icons.lock_outline_rounded, color: palette.accent),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
                const SizedBox(height: 18),
                _buildBackupPhoneCard(),
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

  Widget _buildBackupPhoneCard() {
    final palette = MbongoThemeController.current;
    final hasBackup = _backupPhone != null && _backupPhone!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phone_forwarded_rounded, color: palette.accent, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Numero de secours',
                  style: TextStyle(
                    color: AppColors.darkText,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (hasBackup)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Actif',
                    style: TextStyle(
                      color: AppColors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            hasBackup
                ? 'Numero enregistre: $_backupPhone'
                : 'Aucun numero de secours configure.',
            style: const TextStyle(
              color: AppColors.darkMuted,
              fontSize: 12.8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ce numero sera utilise pour recuperer votre compte en cas de blocage.',
            style: TextStyle(
              color: AppColors.darkMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _savingBackupPhone ? null : _showBackupPhoneSheet,
                  icon: Icon(hasBackup ? Icons.edit_rounded : Icons.add_rounded, size: 16),
                  label: Text(hasBackup ? 'Modifier' : 'Ajouter'),
                ),
              ),
              if (hasBackup) ...[
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: _savingBackupPhone ? null : () => _saveBackupPhone(''),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.red,
                    side: const BorderSide(color: AppColors.red),
                  ),
                  child: const Text('Supprimer'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showBackupPhoneSheet() async {
    final palette = MbongoThemeController.current;
    final ctrl = TextEditingController(text: _backupPhone ?? '');
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: palette.panel,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.phone_forwarded_rounded, color: palette.accent),
                  const SizedBox(width: 10),
                  const Text(
                    'Numero de secours',
                    style: TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Ce numero sera utilise uniquement pour la recuperation de compte.',
                style: TextStyle(
                  color: AppColors.textSoft,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.phone,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Numero de telephone',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _saveBackupPhone(ctrl.text.trim());
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveBackupPhone(String phone) async {
    setState(() => _savingBackupPhone = true);
    try {
      await ApiService.updateBackupPhone(phone);
      setState(() => _backupPhone = phone.isEmpty ? null : phone);
      _toast(phone.isEmpty ? 'Numero de secours supprime.' : 'Numero de secours enregistre.');
    } catch (_) {
      _toast('Impossible de mettre a jour le numero de secours.');
    } finally {
      if (mounted) setState(() => _savingBackupPhone = false);
    }
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
