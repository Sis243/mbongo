import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart' as camera;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api/dio_client.dart' as dio_client;
import '../core/theme/app_colors.dart';
import '../core/theme/mbongo_theme.dart';
import '../core/utils/phone_validator.dart';
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
  final emailCtrl = TextEditingController();
  final pinCtrl = TextEditingController();
  final documentNumberCtrl = TextEditingController();
  final sheetNameCtrl = TextEditingController();

  bool loading = false;
  bool hidePin = true;
  bool _acceptCgu = false;
  String documentType = 'Carte d\'électeur';
  int _currentStep = 0;

  bool get _requiresBackPhoto => documentType != 'Passeport';
  XFile? kycSelfie;
  XFile? kycDocumentFront;
  XFile? kycDocumentBack;

  // ── Steps ────────────────────────────────────────────────────────────────
  List<String> get _stepLabels => widget.resumeKyc
      ? ['Document', 'Photos', 'Confirmation']
      : ['Compte', 'Document', 'Photos', 'Confirmation'];

  int get _stepCount => _stepLabels.length;

  // Normalised index (resumeKyc shifts real _currentStep by 1)
  int get _displayStep =>
      widget.resumeKyc ? _currentStep - 1 : _currentStep;

  bool get _identityFieldsReady =>
      nameCtrl.text.trim().isNotEmpty &&
      phoneCtrl.text.trim().isNotEmpty &&
      (widget.resumeKyc || pinCtrl.text.trim().length >= 4);

  bool get _documentFieldsReady =>
      documentNumberCtrl.text.trim().isNotEmpty;

  bool get _photosReady =>
      kycDocumentFront != null &&
      kycSelfie != null &&
      (!_requiresBackPhoto || kycDocumentBack != null);

  bool get _isKycReady =>
      _identityFieldsReady && _documentFieldsReady && _photosReady;

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _identityFieldsReady;
      case 1:
        return _documentFieldsReady;
      case 2:
        return _photosReady;
      default:
        return true;
    }
  }

  void _nextStep() {
    if (!_canProceed()) {
      _toast(_stepErrorMessage());
      return;
    }
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    final min = widget.resumeKyc ? 1 : 0;
    if (_currentStep > min) setState(() => _currentStep--);
  }

  String _stepErrorMessage() {
    switch (_currentStep) {
      case 0:
        if (nameCtrl.text.trim().isEmpty) return 'Entrez votre nom complet.';
        if (phoneCtrl.text.trim().isEmpty) return 'Entrez votre numéro de téléphone.';
        return 'Le code PIN doit contenir au moins 4 chiffres.';
      case 1:
        return 'Entrez le numéro de votre document.';
      case 2:
        if (kycDocumentFront == null) return 'Ajoutez le recto de votre pièce d\'identité.';
        if (_requiresBackPhoto && kycDocumentBack == null) return 'Ajoutez le verso de votre pièce d\'identité.';
        return 'Prenez votre selfie avec la feuille MBONGO.';
      default:
        return '';
    }
  }

  // ── Business logic ────────────────────────────────────────────────────────
  Future<void> createAccount() async {
    final name = nameCtrl.text.trim();
    final phone = PhoneValidator.normalize(phoneCtrl.text);
    final email = emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim();
    final pin = pinCtrl.text.trim();
    final documentNumber = documentNumberCtrl.text.trim();
    // Auto-fill sheetName si pas encore rempli (champ caché dans le nouveau design)
    if (sheetNameCtrl.text.isEmpty) sheetNameCtrl.text = name;
    final sheetName = sheetNameCtrl.text.trim();

    if (!_acceptCgu) {
      _toast('Veuillez accepter les Conditions Générales d\'Utilisation pour continuer.');
      return;
    }
    if (name.isEmpty || (!widget.resumeKyc && pin.isEmpty) ||
        documentNumber.isEmpty) {
      _toast('Veuillez remplir les champs essentiels.');
      return;
    }
    final phoneError = PhoneValidator.errorMessage(phone);
    if (phoneError != null) {
      _toast(phoneError);
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

    if (!widget.resumeKyc) {
      try {
        await ref.read(authProvider.notifier).register(
              name: name, phone: phone, pin: pin, email: email,
            );
      } catch (e) {
        if (!mounted) return;
        setState(() => loading = false);
        if (e is dio_client.ApiException) {
          _toast(e.message);
        } else {
          _toast('Création du compte impossible. Vérifiez votre connexion et réessayez.');
        }
        return;
      }
      await ProfilePersistenceService.savePhoneVerified(false);
      await ProfilePersistenceService.savePinConfigured(true);
      await ProfilePersistenceService.savePhotoVerified(false);
      await ProfilePersistenceService.savePremiumEligible(false);
      await AuthService.setLoggedIn(true);
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
    context.go('/home');

    unawaited(_uploadKycInBackground(
      documentType: documentType,
      frontPath: kycDocumentFront!.path,
      backPath: kycDocumentBack?.path ?? '',
      selfiePath: kycSelfie!.path,
    ));
  }

  Future<void> _uploadKycInBackground({
    required String documentType,
    required String frontPath,
    required String backPath,
    required String selfiePath,
  }) async {
    try {
      await ApiService.submitKyc(
        documentType: documentType,
        frontPath: frontPath,
        backPath: backPath,
        selfiePath: selfiePath,
      );
      await AuthService.setKycSubmitted(true);
      await AuthService.setKycStatus('en_attente');
      await AuthService.setKycSubmittedAt(DateTime.now().toIso8601String());
      await AuthService.setKycUploadFailed(false);
    } catch (_) {
      await AuthService.setKycUploadFailed(true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'L\'envoi KYC a échoué — réessayez depuis votre profil.',
            ),
            backgroundColor: Color(0xFFB00020),
            duration: Duration(seconds: 6),
          ),
        );
      }
    }
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
    if (widget.resumeKyc) _currentStep = 1;
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
    const validDocTypes = ['Carte nationale', 'Carte d\'électeur', 'Passeport', 'Permis de conduire'];
    setState(() {
      documentType = validDocTypes.contains(savedDocumentType) ? savedDocumentType : documentType;
      documentNumberCtrl.text = savedDocumentNumber;
      sheetNameCtrl.text = savedSheetName;
      if (selfiePath != null && selfiePath.isNotEmpty) kycSelfie = XFile(selfiePath);
      if (frontPath != null && frontPath.isNotEmpty) kycDocumentFront = XFile(frontPath);
      if (backPath != null && backPath.isNotEmpty) kycDocumentBack = XFile(backPath);
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

  // ── Photo pickers ─────────────────────────────────────────────────────────
  Future<void> _pickKycSelfie(ImageSource source) async {
    try {
      final picked = source == ImageSource.camera
          ? await _captureWithCamera(
              lensDirection: camera.CameraLensDirection.front,
              title: 'Selfie KYC',
            )
          : await _picker.pickImage(
              source: source, imageQuality: 45,
              maxWidth: 900, maxHeight: 900,
              preferredCameraDevice: CameraDevice.front,
            );
      if (picked == null) return;
      if (!File(picked.path).existsSync()) { _toast('Le selfie importé est introuvable.'); return; }
      if (!mounted) return;
      setState(() => kycSelfie = picked);
      await _persistDraft();
    } catch (error) {
      _toast(_cameraErrorMessage(error, fallback: 'Impossible de capturer le selfie KYC.'));
    }
  }

  Future<void> _pickKycDocument({required bool isFront, required ImageSource source}) async {
    try {
      final picked = source == ImageSource.camera
          ? await _captureWithCamera(
              lensDirection: camera.CameraLensDirection.back,
              title: isFront ? 'Document recto' : 'Document verso',
            )
          : await _picker.pickImage(
              source: source, imageQuality: 45,
              maxWidth: 900, maxHeight: 900,
              preferredCameraDevice: CameraDevice.rear,
            );
      if (picked == null || !mounted) return;
      if (!File(picked.path).existsSync()) { _toast('La pièce importée est introuvable.'); return; }
      setState(() {
        if (isFront) { kycDocumentFront = picked; } else { kycDocumentBack = picked; }
      });
      await _persistDraft();
    } catch (error) {
      _toast(_cameraErrorMessage(error, fallback: 'Impossible d\'importer la pièce.'));
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
      if (!await file.exists()) { _toast('Le fichier sélectionné est introuvable.'); return; }

      // Vérifier la taille — fichier trop grand → impossible d'envoyer à Vercel
      const maxFileSizeBytes = 1.5 * 1024 * 1024; // 1.5 MB par fichier
      final fileSize = await file.length();
      if (fileSize > maxFileSizeBytes) {
        if (!mounted) return;
        _toast('Fichier trop volumineux (${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB). '
            'Utilisez la caméra ou la galerie pour une meilleure compression.');
        return;
      }

      final picked = XFile(path, name: result!.files.single.name);
      if (!mounted) return;
      setState(() {
        if (isFront) { kycDocumentFront = picked; } else { kycDocumentBack = picked; }
      });
      await _persistDraft();
    } catch (_) {
      _toast('Impossible d\'importer ce document.');
    }
  }

  Future<void> _captureKycSelfie() async => _pickKycSelfie(ImageSource.camera);

  Future<XFile?> _captureWithCamera({
    required camera.CameraLensDirection lensDirection,
    required String title,
  }) async {
    if (!mounted) return null;
    return Navigator.push<XFile>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _KycCameraCaptureScreen(lensDirection: lensDirection, title: title),
      ),
    );
  }

  String _cameraErrorMessage(Object error, {required String fallback}) {
    final message = error.toString().toLowerCase();
    if (message.contains('camera_access_denied') || message.contains('permission')) {
      return 'Autorisez la caméra pour capturer le document KYC.';
    }
    if (message.contains('no_available_camera')) {
      return 'Aucune caméra disponible sur cet appareil.';
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
            border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _pickerAction(
                icon: Icons.document_scanner_rounded,
                title: 'Scanner avec la caméra',
                subtitle: 'Capturer le $side du document',
                onTap: () { Navigator.pop(context); _pickKycDocument(isFront: isFront, source: ImageSource.camera); },
              ),
              const SizedBox(height: 10),
              _pickerAction(
                icon: Icons.photo_library_rounded,
                title: 'Importer depuis la galerie',
                subtitle: 'Choisir une image déjà disponible',
                onTap: () { Navigator.pop(context); _pickKycDocument(isFront: isFront, source: ImageSource.gallery); },
              ),
              const SizedBox(height: 10),
              _pickerAction(
                icon: Icons.upload_file_rounded,
                title: 'Importer un fichier',
                subtitle: 'Image ou PDF du $side',
                onTap: () { Navigator.pop(context); _pickKycDocumentFile(isFront: isFront); },
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: MbongoSubAppBar(
        title: widget.resumeKyc ? 'Mon dossier KYC' : 'Créer mon compte',
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: MbongoMoneyParticles(
                color: palette.accent, count: 16, opacity: 0.08, height: 0,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildStepIndicator(palette),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                    children: [
                      const SizedBox(height: 12),
                      _buildCurrentStep(palette),
                      const SizedBox(height: 20),
                      _buildNavButtons(palette),
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

  // ── Step indicator ────────────────────────────────────────────────────────
  Widget _buildStepIndicator(MbongoThemePalette palette) {
    final display = _displayStep;
    return Container(
      color: palette.shellBottom,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Column(
        children: [
          Row(
            children: List.generate(_stepCount * 2 - 1, (i) {
              if (i.isOdd) {
                final stepIdx = i ~/ 2;
                final filled = stepIdx < display;
                return Expanded(
                  child: Container(
                    height: 2,
                    color: filled
                        ? palette.accent
                        : AppColors.border.withValues(alpha: 0.3),
                  ),
                );
              }
              final stepIdx = i ~/ 2;
              final isActive = stepIdx == display;
              final isDone = stepIdx < display;
              return Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? palette.accent
                      : isActive
                          ? palette.accent.withValues(alpha: 0.15)
                          : palette.panel,
                  border: Border.all(
                    color: isActive || isDone
                        ? palette.accent
                        : AppColors.border.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: isDone
                      ? Icon(Icons.check_rounded, size: 15, color: Colors.white)
                      : Text(
                          '${stepIdx + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: isActive ? palette.accent : AppColors.textSoft,
                          ),
                        ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(_stepCount, (i) {
              final isActive = i == display;
              return Expanded(
                child: Text(
                  _stepLabels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                    color: isActive ? palette.accent : AppColors.textSoft,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Current step dispatcher ───────────────────────────────────────────────
  Widget _buildCurrentStep(MbongoThemePalette palette) {
    switch (_currentStep) {
      case 0:
        return _buildStepCompte(palette);
      case 1:
        return _buildStepDocument(palette);
      case 2:
        return _buildStepPhotos(palette);
      case 3:
        return _buildStepConfirmation(palette);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Step 0 : Compte ───────────────────────────────────────────────────────
  Widget _buildStepCompte(MbongoThemePalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader(
          palette: palette,
          icon: Icons.person_rounded,
          title: 'Vos informations',
          subtitle: 'Renseignez votre identité et créez votre code PIN sécurisé.',
        ),
        const SizedBox(height: 18),
        _sectionCard(
          palette: palette,
          child: Column(
            children: [
              TextField(
                controller: nameCtrl,
                onChanged: (_) { setState(() {}); _persistDraft(); },
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                onChanged: (_) { setState(() {}); _persistDraft(); },
                decoration: const InputDecoration(
                  labelText: 'Numéro de téléphone',
                  hintText: '0812345678',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Adresse email (optionnelle)',
                  hintText: 'vous@exemple.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pinCtrl,
                onChanged: (_) => setState(() {}),
                keyboardType: TextInputType.number,
                obscureText: hidePin,
                decoration: InputDecoration(
                  labelText: 'Code PIN (min. 4 chiffres)',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => hidePin = !hidePin),
                    icon: Icon(hidePin ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _infoTip(
          icon: Icons.shield_outlined,
          color: AppColors.cyan,
          text: 'Votre PIN est chiffré localement. Aucun agent Mbongo ne vous le demandera.',
        ),
      ],
    );
  }

  // ── Step 1 : Document ─────────────────────────────────────────────────────
  Widget _buildStepDocument(MbongoThemePalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader(
          palette: palette,
          icon: Icons.badge_rounded,
          title: 'Pièce d\'identité',
          subtitle: 'Choisissez le type de document et entrez son numéro.',
        ),
        const SizedBox(height: 18),
        _sectionCard(
          palette: palette,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                key: ValueKey(documentType),
                initialValue: documentType,
                dropdownColor: palette.panel,
                style: const TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w700),
                decoration: const InputDecoration(
                  labelText: 'Type de document',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'Carte nationale', child: Text('Carte nationale')),
                  DropdownMenuItem(value: 'Carte d\'électeur', child: Text('Carte d\'électeur')),
                  DropdownMenuItem(value: 'Passeport', child: Text('Passeport')),
                  DropdownMenuItem(value: 'Permis de conduire', child: Text('Permis de conduire')),
                ],
                onChanged: (value) {
                  if (value != null) { setState(() => documentType = value); _persistDraft(); }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: documentNumberCtrl,
                onChanged: (_) { setState(() {}); _persistDraft(); },
                decoration: const InputDecoration(
                  labelText: 'Numéro du document',
                  prefixIcon: Icon(Icons.numbers_rounded),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _infoTip(
          icon: Icons.info_outline_rounded,
          color: AppColors.gold,
          text: documentType == 'Passeport'
              ? 'Pour le passeport, une seule photo (page d\'identité) sera demandée à l\'étape suivante.'
              : 'Vous devrez photographier le recto ET le verso de cette pièce à l\'étape suivante.',
        ),
      ],
    );
  }

  // ── Step 2 : Photos ───────────────────────────────────────────────────────
  Widget _buildStepPhotos(MbongoThemePalette palette) {
    // Auto-fill nom sur feuille depuis step 0
    if (sheetNameCtrl.text.isEmpty && nameCtrl.text.isNotEmpty) {
      sheetNameCtrl.text = nameCtrl.text.trim();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader(
          palette: palette,
          icon: Icons.camera_alt_rounded,
          title: 'Photos du dossier KYC',
          subtitle: 'Suivez attentivement les instructions pour chaque photo.',
        ),
        const SizedBox(height: 20),

        // ══════════════════════════════════════════════════════
        // SECTION 1 — PIÈCE D'IDENTITÉ
        // ══════════════════════════════════════════════════════
        _kycSectionTitle(
          icon: Icons.badge_rounded,
          label: documentType == 'Passeport'
              ? 'Page d\'identité du passeport'
              : 'Pièce d\'identité — Recto & Verso',
          color: palette.accent,
        ),
        const SizedBox(height: 10),

        // Guide document
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.accent.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.accent.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline_rounded, color: palette.accent, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Pour une photo valide :',
                    style: TextStyle(color: palette.accent, fontWeight: FontWeight.w800, fontSize: 12.5),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _kycGuideItem('Posez le document sur une surface plate'),
              _kycGuideItem('Bon éclairage — sans reflets ni ombres'),
              _kycGuideItem('Tous les 4 coins du document visibles'),
              _kycGuideItem('Texte parfaitement lisible'),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (documentType == 'Passeport')
          _captureCard(
            title: 'Page d\'identité du passeport',
            file: kycDocumentFront,
            onTap: () => _showDocumentPickerSheet(true),
          )
        else ...[
          _captureCard(
            title: 'Recto — Face avant',
            file: kycDocumentFront,
            onTap: () => _showDocumentPickerSheet(true),
          ),
          const SizedBox(height: 10),
          _captureCard(
            title: 'Verso — Face arrière',
            file: kycDocumentBack,
            onTap: () => _showDocumentPickerSheet(false),
          ),
        ],

        const SizedBox(height: 28),

        // ══════════════════════════════════════════════════════
        // SECTION 2 — SELFIE AVEC FEUILLE
        // ══════════════════════════════════════════════════════
        _kycSectionTitle(
          icon: Icons.face_rounded,
          label: 'Selfie de vérification',
          color: AppColors.cyan,
        ),
        const SizedBox(height: 10),

        // Bloc instruction principal
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cyan.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre
              Row(
                children: [
                  const Icon(Icons.smart_toy_rounded, color: AppColors.cyan, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Instructions étape par étape',
                    style: TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Illustration — feuille à tenir
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.face_rounded, color: Colors.white70, size: 50),
                    const SizedBox(height: 10),
                    // Feuille simulée
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          Text(
                            nameCtrl.text.trim().isNotEmpty
                                ? nameCtrl.text.trim().toUpperCase()
                                : 'VOTRE NOM COMPLET',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'MBONGO',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Étapes
              _kycSelfieStep('1', 'Prenez une feuille blanche et un stylo ou marqueur'),
              _kycSelfieStep('2', 'Écrivez votre nom complet en haut de la feuille'),
              _kycSelfieStep('3', 'Écrivez le mot  MBONGO  en dessous, en grandes lettres'),
              _kycSelfieStep('4', 'Tenez la feuille devant votre visage face à la caméra frontale'),
              _kycSelfieStep('5', 'Votre visage ET la feuille doivent être entièrement visibles'),
              _kycSelfieStep('6', 'Bonne luminosité — le texte doit être lisible'),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Zone de capture selfie
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.panelAlt,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: kycSelfie != null
                  ? AppColors.green.withValues(alpha: 0.5)
                  : AppColors.cyan.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              if (kycSelfie != null) ...[
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(kycSelfie!.path),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, color: Colors.white, size: 13),
                            SizedBox(width: 4),
                            Text('Selfie ajouté', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ] else ...[
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_a_photo_rounded, color: AppColors.cyan, size: 28),
                        SizedBox(height: 5),
                        Text('Aucun selfie pris', style: TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w700, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _captureKycSelfie,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cyan,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.face_rounded, size: 20),
                  label: Text(
                    kycSelfie == null ? 'Prendre le selfie avec la feuille' : 'Reprendre le selfie',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _kycSectionTitle({required IconData icon, required String label, required Color color}) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _kycGuideItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_rounded, size: 13, color: AppColors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.textSoft, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kycSelfieStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(color: AppColors.cyan, shape: BoxShape.circle),
            child: Center(
              child: Text(number, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(color: AppColors.text, fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Step 3 : Confirmation ─────────────────────────────────────────────────
  Widget _buildStepConfirmation(MbongoThemePalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader(
          palette: palette,
          icon: Icons.check_circle_outline_rounded,
          title: 'Récapitulatif',
          subtitle: 'Vérifiez vos informations avant d\'envoyer le dossier.',
        ),
        const SizedBox(height: 18),

        // Summary rows
        _sectionCard(
          palette: palette,
          child: Column(
            children: [
              _summaryRow(icon: Icons.person_rounded, label: 'Nom', value: nameCtrl.text.trim()),
              _divider(),
              _summaryRow(icon: Icons.phone_rounded, label: 'Téléphone', value: phoneCtrl.text.trim()),
              _divider(),
              _summaryRow(icon: Icons.badge_rounded, label: 'Document', value: documentType),
              _divider(),
              _summaryRow(icon: Icons.numbers_rounded, label: 'Numéro', value: documentNumberCtrl.text.trim()),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Photo checklist
        _sectionCard(
          palette: palette,
          child: Column(
            children: [
              _photoCheckRow('Recto du document', kycDocumentFront != null),
              if (_requiresBackPhoto) ...[
                _divider(),
                _photoCheckRow('Verso du document', kycDocumentBack != null),
              ],
              _divider(),
              _photoCheckRow('Selfie avec feuille MBONGO', kycSelfie != null),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (!_isKycReady)
          _infoTip(
            icon: Icons.warning_amber_rounded,
            color: AppColors.gold,
            text: 'Dossier incomplet. Revenez en arrière pour compléter les étapes manquantes.',
          ),
        if (_isKycReady)
          _infoTip(
            icon: Icons.verified_rounded,
            color: AppColors.green,
            text: 'Dossier complet. Vous pouvez soumettre pour vérification.',
          ),
      ],
    );
  }

  Widget _summaryRow({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.muted),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: AppColors.textSoft, fontSize: 13, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(
            value.isEmpty ? '—' : value,
            style: TextStyle(
              color: value.isEmpty ? AppColors.muted : AppColors.darkText,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoCheckRow(String label, bool done) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 18,
            color: done ? AppColors.green : AppColors.gold,
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: AppColors.darkText, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, thickness: 0.5, color: AppColors.border);

  // ── Navigation buttons ────────────────────────────────────────────────────
  Widget _buildNavButtons(MbongoThemePalette palette) {
    final isFirst = _currentStep == (widget.resumeKyc ? 1 : 0);
    final isLast = _currentStep == 3;

    return Column(
      children: [
        if (isLast && !widget.resumeKyc) ...[
          GestureDetector(
            onTap: () => setState(() => _acceptCgu = !_acceptCgu),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: _acceptCgu
                    ? AppColors.green.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _acceptCgu
                      ? AppColors.green.withValues(alpha: 0.35)
                      : AppColors.border.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: _acceptCgu,
                      onChanged: (v) => setState(() => _acceptCgu = v ?? false),
                      activeColor: AppColors.green,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(color: AppColors.textSoft, fontSize: 13, height: 1.45),
                        children: [
                          TextSpan(text: 'J\'accepte les '),
                          TextSpan(
                            text: 'Conditions Générales d\'Utilisation',
                            style: TextStyle(
                              color: AppColors.cyan,
                              fontWeight: FontWeight.w800,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(text: ' et la '),
                          TextSpan(
                            text: 'Politique de Confidentialité',
                            style: TextStyle(
                              color: AppColors.cyan,
                              fontWeight: FontWeight.w800,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(text: ' de MBONGO. Je certifie que les informations fournies sont exactes.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: loading ? null : (isLast ? createAccount : _nextStep),
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.accentStrong,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: loading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                : Text(
                    isLast
                        ? (widget.resumeKyc ? 'Soumettre mon dossier KYC' : 'Créer mon compte MBONGO')
                        : 'Continuer',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
          ),
        ),
        if (!isFirst) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _prevStep,
              child: const Text('Retour'),
            ),
          ),
        ],
      ],
    );
  }

  // ── Shared UI helpers ─────────────────────────────────────────────────────
  Widget _stepHeader({
    required MbongoThemePalette palette,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette.bannerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: palette.glow.withValues(alpha: 0.14), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Color(0xFFD0DCF0), fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required MbongoThemePalette palette, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.25)),
      ),
      child: child,
    );
  }

  Widget _infoTip({required IconData icon, required Color color, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: AppColors.textSoft, fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.4))),
        ],
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
          decoration: BoxDecoration(color: palette.panel, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: palette.panelAlt, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: palette.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: AppColors.textSoft, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _captureCard({required String title, required XFile? file, required VoidCallback onTap}) {
    final ready = file != null;
    final isPdf = file != null && file.path.toLowerCase().endsWith('.pdf');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ready ? AppColors.green.withValues(alpha: 0.30) : AppColors.border.withValues(alpha: 0.9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (file != null)
            isPdf
                ? _pdfPreview(file.path)
                : ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(File(file.path), height: 220, width: double.infinity, fit: BoxFit.cover),
                  )
          else
            Container(
              height: 220, width: double.infinity,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.badge_outlined, size: 48, color: AppColors.textSoft),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(onPressed: onTap, child: Text(file == null ? 'Capturer' : 'Reprendre')),
          ),
        ],
      ),
    );
  }

  Widget _pdfPreview(String path) {
    final fileName = path.split(Platform.pathSeparator).last;
    return Container(
      height: 86, width: double.infinity,
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
          Expanded(child: Text(fileName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.darkText, fontSize: 12, fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}

// ── Bottom private widgets ────────────────────────────────────────────────────

class _KycCameraCaptureScreen extends StatefulWidget {
  final camera.CameraLensDirection lensDirection;
  final String title;

  const _KycCameraCaptureScreen({required this.lensDirection, required this.title});

  @override
  State<_KycCameraCaptureScreen> createState() => _KycCameraCaptureScreenState();
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
      if (cameras.isEmpty) throw camera.CameraException('no_camera', 'Aucune caméra disponible');
      final selected = cameras.firstWhere(
        (item) => item.lensDirection == widget.lensDirection,
        orElse: () => cameras.first,
      );
      final controller = camera.CameraController(selected, camera.ResolutionPreset.medium, enableAudio: false);
      _controller = controller;
      await controller.initialize();
      if (!mounted) return;
      setState(() {});
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Caméra indisponible. Vérifiez la permission ou utilisez la galerie.');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized || _capturing) return;
    setState(() => _capturing = true);
    try {
      final file = await ctrl.takePicture();
      if (!mounted) return;
      Navigator.pop(context, file);
    } catch (_) {
      if (!mounted) return;
      setState(() => _capturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder<void>(
        future: _initializing,
        builder: (context, snapshot) {
          if (_error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
              ),
            );
          }
          final ctrl = _controller;
          if (ctrl == null || !ctrl.value.isInitialized) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          return Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Positioned.fill(child: camera.CameraPreview(ctrl)),
              Padding(
                padding: const EdgeInsets.only(bottom: 36),
                child: GestureDetector(
                  onTap: _capture,
                  child: Container(
                    width: 70, height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.white54, width: 4),
                    ),
                    child: _capturing
                        ? const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black))
                        : const Icon(Icons.camera_alt_rounded, color: Colors.black, size: 30),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
