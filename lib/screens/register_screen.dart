import 'dart:io';

import 'package:camera/camera.dart' as camera;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/mbongo_theme.dart';
import '../features/auth/presentation/auth_notifier.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/profile_persistence_service.dart';
import '../widgets/common/mbongo_money_particles.dart';
import '../widgets/common/mbongo_sub_app_bar.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final bool resumeKyc;

  const RegisterScreen({
    super.key,
    this.resumeKyc = false,
  });

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final ImagePicker _picker = ImagePicker();
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final pinCtrl = TextEditingController();
  final documentNumberCtrl = TextEditingController();
  final sheetNameCtrl = TextEditingController();

  bool loading = false;
  bool hidePin = true;
  String documentType = 'Carte d\'électeur';

  bool get _requiresBackPhoto => documentType != 'Passeport';
  XFile? kycSelfie;
  XFile? kycDocumentFront;
  XFile? kycDocumentBack;

  int get _kycCompletedSteps {
    var total = 0;
    if (nameCtrl.text.trim().isNotEmpty) total++;
    if (phoneCtrl.text.trim().isNotEmpty) total++;
    if (!widget.resumeKyc && pinCtrl.text.trim().length >= 4) total++;
    if (documentNumberCtrl.text.trim().isNotEmpty) total++;
    if (sheetNameCtrl.text.trim().isNotEmpty) total++;
    if (kycSelfie != null) total++;
    if (kycDocumentFront != null) total++;
    if (_requiresBackPhoto && kycDocumentBack != null) total++;
    return total;
  }

  int get _kycTotalSteps {
    final base = widget.resumeKyc ? 6 : 7;
    return _requiresBackPhoto ? base + 1 : base;
  }

  double get _kycProgress => _kycCompletedSteps / _kycTotalSteps;

  bool get _identityFieldsReady =>
      nameCtrl.text.trim().isNotEmpty &&
      phoneCtrl.text.trim().isNotEmpty &&
      (widget.resumeKyc || pinCtrl.text.trim().length >= 4);

  bool get _isKycReady =>
      _identityFieldsReady &&
      documentNumberCtrl.text.trim().isNotEmpty &&
      sheetNameCtrl.text.trim().isNotEmpty &&
      kycSelfie != null &&
      kycDocumentFront != null &&
      (!_requiresBackPhoto || kycDocumentBack != null);

  Future<void> createAccount() async {
    final name = nameCtrl.text.trim();
    final phone = phoneCtrl.text.trim();
    final pin = pinCtrl.text.trim();
    final documentNumber = documentNumberCtrl.text.trim();
    final sheetName = sheetNameCtrl.text.trim();

    if (name.isEmpty ||
        phone.isEmpty ||
        (!widget.resumeKyc && pin.isEmpty) ||
        documentNumber.isEmpty ||
        sheetName.isEmpty) {
      _toast('Veuillez remplir les champs essentiels.');
      return;
    }

    if (kycSelfie == null) {
      _toast('Ajoutez le selfie KYC avec la feuille MBONGO.');
      return;
    }

    if (kycDocumentFront == null) {
      _toast(documentType == 'Passeport'
          ? 'Ajoutez la photo de la page d\'identité du passeport.'
          : 'Ajoutez le recto de votre pièce d\'identité.');
      return;
    }
    if (_requiresBackPhoto && kycDocumentBack == null) {
      _toast('Ajoutez le verso de votre pièce d\'identité.');
      return;
    }

    if (!widget.resumeKyc && pin.length < 4) {
      _toast('Le code PIN doit contenir au moins 4 chiffres.');
      return;
    }

    setState(() => loading = true);
    try {
      // Étape 1 — création du compte (bloquante)
      if (!widget.resumeKyc) {
        await ref.read(authProvider.notifier).register(
              name: name,
              phone: phone,
              pin: pin,
            );
        await ProfilePersistenceService.savePhoneVerified(false);
        await ProfilePersistenceService.savePinConfigured(true);
        await ProfilePersistenceService.savePhotoVerified(false);
        await ProfilePersistenceService.savePremiumEligible(false);
        await AuthService.setLoggedIn(true);
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      _toast(error.message);
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
      _toast('Création du compte impossible. Vérifiez votre connexion et réessayez.');
      return;
    }

    // Étape 2 — soumission KYC (non bloquante pour la navigation)
    String? kycError;
    try {
      await ApiService.submitKyc(
        documentType: documentType,
        frontPath: kycDocumentFront!.path,
        backPath: kycDocumentBack?.path ?? '',
        selfiePath: kycSelfie!.path,
      );
      await AuthService.setKycSubmitted(true);
      await AuthService.setKycStatus('en_attente');
      await AuthService.setKycSubmittedAt(DateTime.now().toIso8601String());
    } catch (_) {
      kycError = 'Dossier KYC non envoyé. Vous pourrez le soumettre depuis l\'accueil.';
    }

    await AuthService.setKycDocumentType(documentType);
    await AuthService.setKycDocumentNumber(documentNumber);
    await AuthService.setKycSheetName(sheetName);
    await AuthService.setKycSelfiePath(kycSelfie!.path);
    await AuthService.setKycDocumentFrontPath(kycDocumentFront!.path);
    await AuthService.setKycDocumentBackPath(kycDocumentBack?.path ?? '');
    await AuthService.setKycRefusalReason('');
    await AuthService.clearRegisterDraft();

    if (!mounted) return;
    setState(() => loading = false);
    if (kycError != null) {
      _toast(kycError);
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    if (!mounted) return;
    context.go('/home');
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    pinCtrl.dispose();
    documentNumberCtrl.dispose();
    sheetNameCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _prefillDraft();
  }

  Future<void> _prefillDraft() async {
    final currentUser = ref.read(authProvider).valueOrNull;
    final draftName = await AuthService.getRegisterDraftName();
    final draftPhone = await AuthService.getRegisterDraftPhone();
    nameCtrl.text = currentUser?.name ?? draftName;
    phoneCtrl.text = currentUser?.phone ?? draftPhone;

    final savedDocumentType = await AuthService.getKycDocumentType();
    final savedDocumentNumber = await AuthService.getKycDocumentNumber();
    final savedSheetName = await AuthService.getKycSheetName();
    final selfiePath = await AuthService.getKycSelfiePath();
    final frontPath = await AuthService.getKycDocumentFrontPath();
    final backPath = await AuthService.getKycDocumentBackPath();

    if (!mounted) return;
    setState(() {
      documentType = savedDocumentType;
      documentNumberCtrl.text = savedDocumentNumber;
      sheetNameCtrl.text = savedSheetName;
      if (selfiePath != null && selfiePath.isNotEmpty) {
        kycSelfie = XFile(selfiePath);
      }
      if (frontPath != null && frontPath.isNotEmpty) {
        kycDocumentFront = XFile(frontPath);
      }
      if (backPath != null && backPath.isNotEmpty) {
        kycDocumentBack = XFile(backPath);
      }
    });
  }

  Future<void> _persistDraft() async {
    await AuthService.setRegisterDraftName(nameCtrl.text.trim());
    await AuthService.setRegisterDraftPhone(phoneCtrl.text.trim());
    await AuthService.setKycDocumentType(documentType);
    await AuthService.setKycDocumentNumber(documentNumberCtrl.text.trim());
    await AuthService.setKycSheetName(sheetNameCtrl.text.trim());
    await AuthService.setKycSelfiePath(kycSelfie?.path ?? '');
    await AuthService.setKycDocumentFrontPath(kycDocumentFront?.path ?? '');
    await AuthService.setKycDocumentBackPath(kycDocumentBack?.path ?? '');
  }

  Future<void> _pickKycSelfie(ImageSource source) async {
    try {
      final picked = source == ImageSource.camera
          ? await _captureWithCamera(
              lensDirection: camera.CameraLensDirection.front,
              title: 'Selfie KYC',
            )
          : await _picker.pickImage(
              source: source,
              imageQuality: 45,
              maxWidth: 900,
              maxHeight: 900,
              preferredCameraDevice: CameraDevice.front,
            );

      if (picked == null) return;
      if (!File(picked.path).existsSync()) {
        _toast('Le selfie importe est introuvable.');
        return;
      }

      if (!mounted) return;
      setState(() => kycSelfie = picked);
      await _persistDraft();
    } catch (error) {
      _toast(_cameraErrorMessage(error,
          fallback: 'Impossible de capturer le selfie KYC maintenant.'));
    }
  }

  Future<void> _pickKycDocument({
    required bool isFront,
    required ImageSource source,
  }) async {
    try {
      final picked = source == ImageSource.camera
          ? await _captureWithCamera(
              lensDirection: camera.CameraLensDirection.back,
              title: isFront ? 'Document recto' : 'Document verso',
            )
          : await _picker.pickImage(
              source: source,
              imageQuality: 45,
              maxWidth: 900,
              maxHeight: 900,
              preferredCameraDevice: CameraDevice.rear,
            );

      if (picked == null || !mounted) return;
      if (!File(picked.path).existsSync()) {
        _toast('La piece importee est introuvable.');
        return;
      }

      setState(() {
        if (isFront) {
          kycDocumentFront = picked;
        } else {
          kycDocumentBack = picked;
        }
      });
      await _persistDraft();
    } catch (error) {
      _toast(_cameraErrorMessage(error,
          fallback: 'Impossible d importer la piece maintenant.'));
    }
  }

  Future<void> _pickKycDocumentFile({required bool isFront}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      );

      final path = result?.files.single.path;
      if (path == null || path.isEmpty) return;

      final file = File(path);
      if (!await file.exists()) {
        _toast('Le fichier selectionne est introuvable.');
        return;
      }

      final picked = XFile(path, name: result!.files.single.name);
      if (!mounted) return;
      setState(() {
        if (isFront) {
          kycDocumentFront = picked;
        } else {
          kycDocumentBack = picked;
        }
      });
      await _persistDraft();
    } catch (_) {
      _toast('Impossible d importer ce document maintenant.');
    }
  }

  Future<void> _captureKycSelfie() async {
    await _pickKycSelfie(ImageSource.camera);
  }

  Future<XFile?> _captureWithCamera({
    required camera.CameraLensDirection lensDirection,
    required String title,
  }) async {
    if (!mounted) return null;
    return Navigator.push<XFile>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _KycCameraCaptureScreen(
          lensDirection: lensDirection,
          title: title,
        ),
      ),
    );
  }

  String _cameraErrorMessage(
    Object error, {
    required String fallback,
  }) {
    final message = error.toString().toLowerCase();
    if (message.contains('camera_access_denied') ||
        message.contains('permission')) {
      return 'Autorisez la camera pour capturer le document KYC.';
    }
    if (message.contains('no_available_camera')) {
      return 'Aucune camera disponible sur cet appareil ou emulateur.';
    }
    return fallback;
  }

  Future<void> _showDocumentPickerSheet(bool isFront) async {
    final side = isFront ? 'recto' : 'verso';
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final palette = MbongoThemeController.current;
        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: palette.panelAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _pickerAction(
                icon: Icons.document_scanner_rounded,
                title: 'Scanner avec la camera',
                subtitle: 'Capturer le $side du document',
                onTap: () {
                  Navigator.pop(context);
                  _pickKycDocument(
                    isFront: isFront,
                    source: ImageSource.camera,
                  );
                },
              ),
              const SizedBox(height: 10),
              _pickerAction(
                icon: Icons.photo_library_rounded,
                title: 'Importer depuis la galerie',
                subtitle: 'Choisir une image deja disponible',
                onTap: () {
                  Navigator.pop(context);
                  _pickKycDocument(
                    isFront: isFront,
                    source: ImageSource.gallery,
                  );
                },
              ),
              const SizedBox(height: 10),
              _pickerAction(
                icon: Icons.upload_file_rounded,
                title: 'Importer un fichier',
                subtitle: 'Image ou PDF du $side',
                onTap: () {
                  Navigator.pop(context);
                  _pickKycDocumentFile(isFront: isFront);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const MbongoSubAppBar(title: 'Creer mon compte'),
      body: Stack(
        children: [
          Positioned.fill(
            child: MbongoMoneyParticles(
              color: palette.accent,
              count: 16,
              opacity: 0.08,
              height: 0,
            ),
          ),
          SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: palette.bannerGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: palette.glow.withValues(alpha: 0.16),
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
                          Container(
                            width: 52,
                            height: 52,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.asset(
                              'assets/icon/mbongo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'MBONGO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Ouverture de compte',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Creer mon compte MBONGO',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.resumeKyc
                            ? 'Votre dossier KYC est recharge. Completez et renvoyez.'
                            : 'Remplissez vos informations pour ouvrir votre compte MBONGO.',
                        style: TextStyle(
                          color: AppColors.textSoft,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const _RegisterTag(label: 'OTP'),
                          const SizedBox(width: 8),
                          if (!widget.resumeKyc) ...[
                            const _RegisterTag(label: 'PIN'),
                            const SizedBox(width: 8),
                          ],
                          const _RegisterTag(label: 'KYC'),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _KycProgress(ready: _isKycReady),
                      const SizedBox(height: 12),
                      _buildDraftMeter(),
                      if (widget.resumeKyc) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Dossier KYC repris automatiquement',
                            style: TextStyle(
                              color: AppColors.text,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: palette.panel,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameCtrl,
                        onChanged: (_) {
                          setState(() {});
                          _persistDraft();
                        },
                        decoration: const InputDecoration(
                          labelText: 'Nom complet',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneCtrl,
                        onChanged: (_) {
                          setState(() {});
                          _persistDraft();
                        },
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Numero de telephone',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      if (!widget.resumeKyc) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: pinCtrl,
                          onChanged: (_) => setState(() {}),
                          keyboardType: TextInputType.number,
                          obscureText: hidePin,
                          decoration: InputDecoration(
                            labelText: 'Code PIN',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() => hidePin = !hidePin);
                              },
                              icon: Icon(
                                hidePin
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      _sectionTitle('Verification d identite (KYC)'),
                      const SizedBox(height: 10),
                      _buildChecklistCard(),
                      const SizedBox(height: 12),
                      _KycStep(
                        index: '1',
                        title: 'Identite',
                        subtitle: widget.resumeKyc
                            ? 'Nom complet et numero deja associes au compte'
                            : 'Nom complet, numero et code PIN',
                      ),
                      const SizedBox(height: 8),
                      const _KycStep(
                        index: '2',
                        title: 'Document',
                        subtitle: 'Choisissez la piece et ajoutez son numero',
                      ),
                      const SizedBox(height: 8),
                      const _KycStep(
                        index: '3',
                        title: 'Selfie avec feuille',
                        subtitle: 'Montrez votre visage et la feuille MBONGO',
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF0E2346),
                              Color(0xFF14305D),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.cyan.withValues(alpha: 0.16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selfie avec feuille manuscrite',
                              style: TextStyle(
                                color: AppColors.text,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Écrivez lisiblement vos noms complets sur une feuille blanche, puis prenez un selfie en tenant la feuille visible.',
                              style: TextStyle(
                                color: AppColors.textSoft,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const _SelfieSilhouetteHint(),
                            const SizedBox(height: 10),
                            const Text(
                              '• Feuille blanche · stylo bleu ou noir\n• Écriture lisible, sans ratures\n• Photo dans un endroit bien éclairé',
                              style: TextStyle(
                                color: AppColors.textSoft,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _sectionTitle('Votre piece d identite'),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: documentType,
                        dropdownColor: palette.panel,
                        style: const TextStyle(
                          color: AppColors.darkText,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Piece d identite',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Carte nationale',
                            child: Text('Carte nationale'),
                          ),
                          DropdownMenuItem(
                            value: 'Carte d\'électeur',
                            child: Text('Carte d\'électeur'),
                          ),
                          DropdownMenuItem(
                            value: 'Passeport',
                            child: Text('Passeport'),
                          ),
                          DropdownMenuItem(
                            value: 'Permis de conduire',
                            child: Text('Permis de conduire'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => documentType = value);
                            _persistDraft();
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: documentNumberCtrl,
                        onChanged: (_) {
                          setState(() {});
                          _persistDraft();
                        },
                        decoration: const InputDecoration(
                          labelText: 'Numero du document',
                          prefixIcon: Icon(Icons.numbers_rounded),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cyan.withValues(alpha: 0.20)),
                        ),
                        child: Text(
                          documentType == 'Passeport'
                              ? 'Prenez une photo claire de la page d\'identité de votre passeport.'
                              : 'Prenez d\'abord la photo du recto, puis celle du verso.',
                          style: const TextStyle(
                            color: AppColors.textSoft,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (documentType == 'Passeport')
                        _captureCard(
                          title: 'Page d\'identité',
                          file: kycDocumentFront,
                          onTap: () => _showDocumentPickerSheet(true),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: _captureCard(
                                title: 'Recto',
                                file: kycDocumentFront,
                                onTap: () => _showDocumentPickerSheet(true),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _captureCard(
                                title: 'Verso',
                                file: kycDocumentBack,
                                onTap: () => _showDocumentPickerSheet(false),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: sheetNameCtrl,
                        onChanged: (_) {
                          setState(() {});
                          _persistDraft();
                        },
                        decoration: const InputDecoration(
                          labelText: 'Nom inscrit sur la feuille MBONGO',
                          prefixIcon: Icon(Icons.edit_note_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.90),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.verified_user_outlined,
                                  color: AppColors.cyan,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  kycSelfie == null
                                      ? 'Selfie KYC non capture'
                                      : 'Selfie KYC pret',
                                  style: const TextStyle(
                                    color: AppColors.darkText,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            if (kycSelfie != null) ...[
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  height: 188,
                                  width: double.infinity,
                                  color: const Color(0xFF081A37),
                                  child: Image.file(
                                    File(kycSelfie!.path),
                                    fit: BoxFit.contain,
                                    alignment: Alignment.topCenter,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _captureKycSelfie,
                              icon: const Icon(Icons.add_a_photo_rounded),
                              label: Text(
                                kycSelfie == null
                                    ? 'Ouvrir la camera selfie'
                                    : 'Reprendre le selfie',
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () =>
                                  _pickKycSelfie(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_rounded),
                              label: const Text('Importer depuis la galerie'),
                            ),
                            const SizedBox(height: 12),
                            _kycStatusCard(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: loading ? null : createAccount,
                        child: loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2.4),
                              )
                            : Text(widget.resumeKyc
                                ? 'Soumettre mon dossier KYC'
                                : 'Creer mon compte MBONGO'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.darkText,
        fontSize: 15,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _pickerAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final palette = MbongoThemeController.current;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.panel,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: palette.panelAlt,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: palette.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.darkText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSoft,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDraftMeter() {
    final completed = _kycCompletedSteps;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Avancement du dossier',
                  style: TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$completed/8',
                style: const TextStyle(
                  color: AppColors.textSoft,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _kycProgress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              valueColor: AlwaysStoppedAnimation<Color>(
                _isKycReady ? AppColors.green : AppColors.cyan,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _isKycReady
                ? 'Le dossier est pret a etre envoye.'
                : 'Les informations deja saisies restent en memoire pour reprendre plus tard.',
            style: const TextStyle(
              color: AppColors.textSoft,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistCard() {
    final items = [
      ('Nom', nameCtrl.text.trim().isNotEmpty),
      ('Telephone', phoneCtrl.text.trim().isNotEmpty),
      if (!widget.resumeKyc) ('PIN', pinCtrl.text.trim().length >= 4),
      ('Numero', documentNumberCtrl.text.trim().isNotEmpty),
      ('Feuille', sheetNameCtrl.text.trim().isNotEmpty),
      ('Selfie', kycSelfie != null),
      ('Recto', kycDocumentFront != null),
      ('Verso', kycDocumentBack != null),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map((item) => _ChecklistChip(label: item.$1, ready: item.$2))
          .toList(),
    );
  }

  Widget _kycStatusCard() {
    final ready = _isKycReady;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: ready
              ? const [Color(0xFF123F2A), Color(0xFF175637)]
              : const [Color(0xFF2A2212), Color(0xFF463617)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            ready ? Icons.verified_rounded : Icons.pending_actions_rounded,
            color: ready ? AppColors.green : AppColors.gold,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              ready
                  ? 'Dossier pret pour verification'
                  : 'Ajoutez les elements manquants pour envoyer le dossier',
              style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _captureCard({
    required String title,
    required XFile? file,
    required VoidCallback onTap,
  }) {
    final ready = file != null;
    final isPdf = file != null && _isPdfPath(file.path);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ready
              ? AppColors.green.withValues(alpha: 0.30)
              : AppColors.border.withValues(alpha: 0.90),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          if (file != null)
            isPdf
                ? _pdfPreview(file.path)
                : ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(file.path),
                      height: 86,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
          else
            Container(
              height: 86,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.badge_outlined,
                color: AppColors.textSoft,
              ),
            ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: onTap,
            child: Text(file == null ? 'Capturer' : 'Reprendre'),
          ),
        ],
      ),
    );
  }

  bool _isPdfPath(String path) => path.toLowerCase().endsWith('.pdf');

  Widget _pdfPreview(String path) {
    final fileName = path.split(Platform.pathSeparator).last;

    return Container(
      height: 86,
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf_rounded, color: AppColors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              fileName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.darkText,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterTag extends StatelessWidget {
  final String label;

  const _RegisterTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _KycProgress extends StatelessWidget {
  final bool ready;

  const _KycProgress({required this.ready});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: _progressCell('Identite', true)),
          const SizedBox(width: 8),
          Expanded(child: _progressCell('Document', true)),
          const SizedBox(width: 8),
          Expanded(child: _progressCell('Selfie', ready)),
        ],
      ),
    );
  }

  Widget _progressCell(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: active
            ? Colors.white.withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withValues(alpha: active ? 1 : 0.72),
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _KycStep extends StatelessWidget {
  final String index;
  final String title;
  final String subtitle;

  const _KycStep({
    required this.index,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.75),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                index,
                style: const TextStyle(
                  color: AppColors.cyan,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSoft,
                    fontSize: 12,
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
}

class _ChecklistChip extends StatelessWidget {
  final String label;
  final bool ready;

  const _ChecklistChip({
    required this.label,
    required this.ready,
  });

  @override
  Widget build(BuildContext context) {
    final color = ready ? AppColors.green : AppColors.gold;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ready ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: ready ? AppColors.darkText : AppColors.textSoft,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelfieSilhouetteHint extends StatelessWidget {
  const _SelfieSilhouetteHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.18)),
      ),
      child: CustomPaint(
        painter: _SilhouettePainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _SilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..color = const Color(0xFF2A4A7A).withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    // Head
    final headCenter = Offset(size.width / 2, size.height * 0.20);
    canvas.drawCircle(headCenter, size.height * 0.12, bodyPaint);

    // Shoulders / torso
    final torsoRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.52),
        width: size.width * 0.30,
        height: size.height * 0.28,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(torsoRect, bodyPaint);

    // Arms (lines)
    final armPaint = Paint()
      ..color = const Color(0xFF2A4A7A).withValues(alpha: 0.65)
      ..strokeWidth = size.width * 0.045
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final paperLeft = size.width / 2 - size.width * 0.22;
    final paperRight = size.width / 2 + size.width * 0.22;
    final paperTop = size.height * 0.50;

    // Left arm
    canvas.drawLine(
      Offset(size.width / 2 - size.width * 0.15, size.height * 0.44),
      Offset(paperLeft, paperTop + size.height * 0.15),
      armPaint,
    );
    // Right arm
    canvas.drawLine(
      Offset(size.width / 2 + size.width * 0.15, size.height * 0.44),
      Offset(paperRight, paperTop + size.height * 0.15),
      armPaint,
    );

    // Paper (white sheet)
    final paperRect = Rect.fromLTRB(
      paperLeft, paperTop, paperRight, size.height * 0.90,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(paperRect, const Radius.circular(5)),
      Paint()..color = Colors.white.withValues(alpha: 0.92),
    );
    // Paper border
    canvas.drawRRect(
      RRect.fromRectAndRadius(paperRect, const Radius.circular(5)),
      Paint()
        ..color = const Color(0xFFCCDDEE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Text on paper — line 1
    _drawText(
      canvas,
      '(NOM & PRÉNOM)',
      Offset(paperRect.left + 6, paperRect.top + 8),
      paperRect.width - 12,
      const TextStyle(
        color: Color(0xFF333333),
        fontSize: 8.5,
        fontWeight: FontWeight.w700,
      ),
    );
    // Text on paper — line 2
    _drawText(
      canvas,
      'MBONGO',
      Offset(paperRect.left + 6, paperRect.top + 26),
      paperRect.width - 12,
      const TextStyle(
        color: Color(0xFF0A3D8F),
        fontSize: 13,
        fontWeight: FontWeight.w900,
      ),
    );
    // Signature line
    _drawText(
      canvas,
      'Signature : ____________',
      Offset(paperRect.left + 6, paperRect.top + 50),
      paperRect.width - 12,
      const TextStyle(
        color: Color(0xFF888888),
        fontSize: 7,
      ),
    );
  }

  void _drawText(Canvas canvas, String text, Offset offset, double maxWidth, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _KycCameraCaptureScreen extends StatefulWidget {
  final camera.CameraLensDirection lensDirection;
  final String title;

  const _KycCameraCaptureScreen({
    required this.lensDirection,
    required this.title,
  });

  @override
  State<_KycCameraCaptureScreen> createState() =>
      _KycCameraCaptureScreenState();
}

class _KycCameraCaptureScreenState extends State<_KycCameraCaptureScreen> {
  camera.CameraController? _controller;
  Future<void>? _initializing;
  String? _error;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _initializing = _setupCamera();
  }

  Future<void> _setupCamera() async {
    try {
      final cameras = await camera.availableCameras();
      if (cameras.isEmpty) {
        throw camera.CameraException(
          'no_camera',
          'Aucune camera disponible',
        );
      }

      final selected = cameras.firstWhere(
        (item) => item.lensDirection == widget.lensDirection,
        orElse: () => cameras.first,
      );

      final controller = camera.CameraController(
        selected,
        camera.ResolutionPreset.medium,
        enableAudio: false,
      );
      _controller = controller;
      await controller.initialize();
      if (!mounted) return;
      setState(() {});
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error =
            'Camera indisponible. Verifiez la permission camera ou la webcam de l emulateur.';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _capturing) {
      return;
    }

    setState(() => _capturing = true);
    try {
      final file = await controller.takePicture();
      if (!mounted) return;
      Navigator.pop(context, XFile(file.path, name: file.name));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _capturing = false;
        _error = 'Capture impossible. Reessayez dans quelques secondes.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: FutureBuilder<void>(
          future: _initializing,
          builder: (context, snapshot) {
            final controller = _controller;
            final ready = controller != null && controller.value.isInitialized;

            return Stack(
              children: [
                Positioned.fill(
                  child: ready
                      ? FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: controller.value.previewSize!.height,
                            height: controller.value.previewSize!.width,
                            child: camera.CameraPreview(controller),
                          ),
                        )
                      : const Center(child: CircularProgressIndicator()),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  top: 16,
                  child: Row(
                    children: [
                      IconButton.filled(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_error != null)
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 126,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 28,
                  child: Center(
                    child: GestureDetector(
                      onTap: ready ? _takePicture : null,
                      child: Container(
                        width: 82,
                        height: 82,
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _capturing ? Colors.white60 : Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
