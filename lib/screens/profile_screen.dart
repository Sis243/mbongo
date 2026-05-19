import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/mbongo_theme.dart';
import '../features/auth/presentation/auth_notifier.dart';
import '../services/auth_service.dart';
import '../services/profile_persistence_service.dart';
import '../widgets/common/mbongo_money_particles.dart';
import 'cards/virtual_cards_screen.dart';
import 'profile/change_pin_screen.dart';
import 'profile/faq_screen.dart';
import 'profile/kyc_status_screen.dart';
import 'profile/security_screen.dart';
import 'profile/settings_screen.dart';
import 'profile/support_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;
  File? _kycSelfie;
  File? _kycDocumentFront;
  File? _kycDocumentBack;
  String _kycStatus = 'non_commence';
  String _kycDocumentType = 'Carte nationale';
  String _kycDocumentNumber = '';
  String _kycSheetName = '';

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _loadKycState();
  }

  Future<void> _loadProfileImage() async {
    final path = await AuthService.getProfileImagePath();
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (!await file.exists()) return;
    if (!mounted) return;
    setState(() => _profileImage = file);
  }

  Future<void> _loadKycState() async {
    final selfiePath = await AuthService.getKycSelfiePath();
    final frontPath = await AuthService.getKycDocumentFrontPath();
    final backPath = await AuthService.getKycDocumentBackPath();
    final status = await AuthService.getKycStatus();
    final documentType = await AuthService.getKycDocumentType();
    final documentNumber = await AuthService.getKycDocumentNumber();
    final sheetName = await AuthService.getKycSheetName();

    Future<File?> existingFile(String? path) async {
      if (path == null || path.isEmpty) return null;
      final file = File(path);
      if (!await file.exists()) return null;
      return file;
    }

    if (!mounted) return;
    setState(() {
      _kycSelfie = null;
      _kycDocumentFront = null;
      _kycDocumentBack = null;
      _kycStatus = status;
      _kycDocumentType = documentType;
      _kycDocumentNumber = documentNumber;
      _kycSheetName = sheetName;
    });

    final selfie = await existingFile(selfiePath);
    final front = await existingFile(frontPath);
    final back = await existingFile(backPath);
    if (!mounted) return;
    setState(() {
      _kycSelfie = selfie;
      _kycDocumentFront = front;
      _kycDocumentBack = back;
    });
  }

  Future<void> _pickProfilePhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );

      if (picked == null) return;

      final imageFile = File(picked.path);
      if (!await imageFile.exists()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image introuvable apres la capture.'),
          ),
        );
        return;
      }

      setState(() {
        _profileImage = imageFile;
      });

      await AuthService.setProfileImagePath(imageFile.path);
      await AuthService.setProfilePhotoVerified(true);
      await ProfilePersistenceService.savePhotoVerified(true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo de profil mise a jour.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d ajouter la photo pour le moment.'),
        ),
      );
    }
  }

  void _showPhotoSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final palette = MbongoThemeController.current;
        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: palette.panelAlt,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _photoAction(
                icon: Icons.camera_alt_rounded,
                title: 'Capturer',
                subtitle: 'Utiliser la camera frontale',
                onTap: () {
                  Navigator.pop(context);
                  _pickProfilePhoto(ImageSource.camera);
                },
              ),
              const SizedBox(height: 10),
              _photoAction(
                icon: Icons.photo_library_rounded,
                title: 'Importer',
                subtitle: 'Choisir une image existante',
                onTap: () {
                  Navigator.pop(context);
                  _pickProfilePhoto(ImageSource.gallery);
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
    final currentUser = ref.watch(authProvider).valueOrNull;
    final name = currentUser?.name ?? 'Client';
    final photoVerified = _kycStatus == 'valide';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: MbongoMoneyParticles(
                color: MbongoThemeController.current.accent,
                count: 14,
                opacity: 0.08,
                height: 0,
              ),
            ),
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
            children: [
              _buildHeader(name),
              const SizedBox(height: 18),
              _buildIdentityBoard(
                name: name,
                photoVerified: photoVerified,
              ),
                                  const SizedBox(height: 18),
                                  _buildKycPanel(context),
                                  const SizedBox(height: 18),
                                  _buildActionTile(
                                    icon: Icons.verified_user_rounded,
                                    title: 'Statut KYC',
                                    subtitle: _kycStatus == 'en_attente'
                                        ? 'Dossier en attente'
                                        : _kycStatus == 'valide'
                                            ? 'Verification confirmee'
                                            : _kycStatus == 'refuse'
                                                ? 'Dossier a reprendre'
                                                : 'Completer le dossier',
                                    color: AppColors.cyan,
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const KycStatusScreen(),
                                        ),
                                      );
                                      if (!context.mounted) return;
                                      await _loadKycState();
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  _buildActionTile(
                                    icon: Icons.shield_outlined,
                                    title: 'Securite',
                                    subtitle: 'Biometrie et alertes',
                                    color: MbongoThemeController.current.accent,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const SecurityScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  _buildActionTile(
                                    icon: Icons.pin_rounded,
                                    title: 'Code PIN',
                                    subtitle: 'Mettre a jour',
                                    color: AppColors.gold,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const ChangePinScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  _buildActionTile(
                                    icon: Icons.credit_card_rounded,
                                    title: 'Cartes',
                                    subtitle: 'Voir les cartes MBONGO',
                                    color: AppColors.primary,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const VirtualCardsScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  _buildActionTile(
                                    icon: Icons.settings_rounded,
                                    title: 'Themes',
                                    subtitle: 'Style et preferences',
                                    color: AppColors.green,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const SettingsScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  _buildActionTile(
                                    icon: Icons.support_agent_rounded,
                                    title: 'Support MBONGO',
                                    subtitle: 'contact@mbongo.cd',
                                    color: AppColors.orange,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const SupportScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  _buildActionTile(
                                    icon: Icons.help_outline_rounded,
                                    title: 'FAQ',
                                    subtitle: 'Questions rapides',
                                    color: MbongoThemeController.current.accentStrong,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const FaqScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  _buildActionTile(
                                    icon: Icons.logout_rounded,
                                    title: 'Deconnexion',
                                    subtitle: 'Fermer la session',
                                    color: AppColors.red,
                                    danger: true,
                                    onTap: () async {
                                      await ref
                                          .read(authProvider.notifier)
                                          .logout();
                                      if (!context.mounted) return;
                                      context.go('/auth/login');
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
  }

  Widget _buildHeader(String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profil',
          style: TextStyle(
            color: MbongoThemeController.current.accent,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Identite, securite, acces',
          style: TextStyle(
            color: MbongoThemeController.current.accent,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildIdentityBoard({
    required String name,
    required bool photoVerified,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MbongoThemeController.current.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _showPhotoSheet,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _profileImage == null
                      ? const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 36,
                        )
                      : Image.file(
                          _profileImage!,
                          key: ValueKey(_profileImage!.path),
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Profil MBONGO',
                      style: TextStyle(
                        color: AppColors.textSoft,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            photoVerified ? 'Photo confirmee' : 'Ajoutez votre photo',
            style: TextStyle(
              color: photoVerified ? AppColors.green : MbongoThemeController.current.accent,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKycPanel(BuildContext context) {
    final statusColor = switch (_kycStatus) {
      'valide' => AppColors.green,
      'refuse' => AppColors.red,
      'en_attente' => AppColors.gold,
      _ => MbongoThemeController.current.accent,
    };

    final statusLabel = switch (_kycStatus) {
      'valide' => 'KYC valide',
      'refuse' => 'KYC refuse',
      'en_attente' => 'KYC en attente',
      _ => 'KYC a completer',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MbongoThemeController.current.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.verified_user_rounded, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Verification d identite',
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _kycStatus == 'valide'
                ? 'Identite confirmee'
                : _kycStatus == 'en_attente'
                    ? 'Revue en cours'
                    : _kycStatus == 'refuse'
                        ? 'Elements a corriger'
                        : 'Dossier a completer',
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _kycLine('Piece', _kycDocumentType),
          _kycLine('Numero', _kycDocumentNumber.isEmpty ? 'A completer' : _kycDocumentNumber),
          _kycLine('Feuille', _kycSheetName.isEmpty ? 'A completer' : _kycSheetName),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _kycThumb('Selfie', _kycSelfie),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _kycThumb('Recto', _kycDocumentFront),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _kycThumb('Verso', _kycDocumentBack),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const KycStatusScreen(),
                  ),
                );
                if (!context.mounted) return;
                await _loadKycState();
              },
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(
                _kycStatus == 'valide' ? 'Voir le dossier' : 'Ouvrir le suivi KYC',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kycLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 74,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSoft,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kycThumb(String label, File? file) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.darkMuted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 70,
          decoration: BoxDecoration(
            color: MbongoThemeController.current.panelAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.22),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: file == null
              ? const Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.darkMuted,
                    size: 18,
                  ),
                )
              : Image.file(file, fit: BoxFit.cover),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final palette = MbongoThemeController.current;
    final background = danger
        ? const LinearGradient(
            colors: [
              Color(0xFF3B1018),
              Color(0xFF5A1820),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [
              palette.panel,
              palette.panel.withValues(alpha: 0.92),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: danger
                ? AppColors.red.withValues(alpha: 0.32)
                : AppColors.border.withValues(alpha: 0.90),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: danger
                          ? const Color(0xFFFFC7CE)
                          : AppColors.textSoft,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: danger ? const Color(0xFFFFC7CE) : AppColors.textSoft,
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MbongoThemeController.current.panel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.24),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: MbongoThemeController.current.accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: MbongoThemeController.current.accent),
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
                      color: AppColors.darkMuted,
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
    );
  }
}
