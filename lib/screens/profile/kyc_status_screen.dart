import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../services/auth_service.dart';
import '../../services/kyc_guard_service.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/mbongo_sub_app_bar.dart';
import '../register_screen.dart';

class KycStatusScreen extends StatefulWidget {
  const KycStatusScreen({super.key});

  @override
  State<KycStatusScreen> createState() => _KycStatusScreenState();
}

class _KycStatusScreenState extends State<KycStatusScreen> {
  bool _loading = true;
  String _status = 'non_commence';
  String _documentType = '';
  String _documentNumber = '';
  String _sheetName = '';
  String _refusalReason = '';
  String _submittedAt = '';
  File? _selfie;
  File? _front;
  File? _back;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _syncRemoteStatus();

    final status = await AuthService.getKycStatus();
    final documentType = await AuthService.getKycDocumentType();
    final documentNumber = await AuthService.getKycDocumentNumber();
    final sheetName = await AuthService.getKycSheetName();
    final refusalReason = await AuthService.getKycRefusalReason();
    final submittedAt = await AuthService.getKycSubmittedAt();
    final selfiePath = await AuthService.getKycSelfiePath();
    final frontPath = await AuthService.getKycDocumentFrontPath();
    final backPath = await AuthService.getKycDocumentBackPath();

    Future<File?> fileOrNull(String? path) async {
      if (path == null || path.isEmpty) return null;
      final file = File(path);
      if (!await file.exists()) return null;
      return file;
    }

    final selfie = await fileOrNull(selfiePath);
    final front = await fileOrNull(frontPath);
    final back = await fileOrNull(backPath);

    if (!mounted) return;
    setState(() {
      _status = status;
      _documentType = documentType;
      _documentNumber = documentNumber;
      _sheetName = sheetName;
      _refusalReason = refusalReason;
      _submittedAt = submittedAt;
      _selfie = selfie;
      _front = front;
      _back = back;
      _loading = false;
    });
  }

  Future<void> _syncRemoteStatus() async {
    await KycGuardService.syncRemoteStatus();
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    final statusColor = switch (_status) {
      'valide' => AppColors.green,
      'refuse' => AppColors.red,
      'en_attente' => AppColors.gold,
      _ => palette.accent,
    };
    final statusLabel = switch (_status) {
      'valide' => 'KYC valide',
      'refuse' => 'KYC refuse',
      'en_attente' => 'KYC en attente',
      _ => 'KYC a completer',
    };

    return AppScaffold(
      appBar: const MbongoSubAppBar(title: 'Statut KYC'),
      useParticles: true,
      primaryParticleColor: palette.accent,
      secondaryParticleColor: AppColors.gold,
      particleDensity: 0.75,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: palette.bannerGradient),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MBONGO',
                        style: TextStyle(
                          color: palette.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        statusLabel,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _submittedAt.isEmpty
                            ? 'Aucun dossier envoye pour le moment.'
                            : 'Envoye le ${_formatSubmittedAt(_submittedAt)}',
                        style: const TextStyle(
                          color: AppColors.textSoft,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _nextStepCard(statusColor),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _progressBand(statusColor, statusLabel),
                const SizedBox(height: 12),
                _infoBand('Statut', statusLabel, statusColor),
                _infoBand(
                  'Piece',
                  _documentType.isEmpty ? 'A completer' : _documentType,
                  AppColors.darkText,
                ),
                _infoBand(
                  'Numero',
                  _documentNumber.isEmpty ? 'A completer' : _documentNumber,
                  AppColors.darkText,
                ),
                _infoBand(
                  'Feuille',
                  _sheetName.isEmpty ? 'A completer' : _sheetName,
                  AppColors.darkText,
                ),
                if (_status == 'refuse' && _refusalReason.isNotEmpty)
                  _reasonCard(_refusalReason),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _thumb('Selfie', _selfie)),
                    const SizedBox(width: 10),
                    Expanded(child: _thumb('Recto', _front)),
                    const SizedBox(width: 10),
                    Expanded(child: _thumb('Verso', _back)),
                  ],
                ),
                const SizedBox(height: 16),
                if (_status == 'valide')
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0D2B1A), Color(0xFF163D27)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.green.withValues(alpha: 0.30),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          color: AppColors.green,
                          size: 30,
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Identite verifiee',
                                style: TextStyle(
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Toutes les operations sont debloquees.',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(resumeKyc: true),
                        ),
                      );
                      if (!mounted) return;
                      await _load();
                    },
                    child: Text(
                      _status == 'en_attente'
                          ? 'Voir et ajuster le dossier'
                          : 'Reprendre le dossier',
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _nextStepCard(Color accent) {
    final text = switch (_status) {
      'valide' =>
        'Votre identite est verifiee. Les operations sensibles sont debloquees.',
      'en_attente' =>
        'Le dossier a bien ete transmis. Vous pouvez verifier les informations ci-dessous pendant la revue.',
      'refuse' =>
        'Le dossier doit etre repris. Corrigez les visuels ou les champs signales avant un nouvel envoi.',
      _ => 'Completez les pieces et le selfie pour lancer la verification.',
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.track_changes_rounded, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressBand(Color accent, String statusLabel) {
    final palette = MbongoThemeController.current;
    final stages = [
      ('Dossier', _status != 'non_commence'),
      ('Revue', _status == 'en_attente' || _status == 'valide'),
      ('Validation', _status == 'valide'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Icon(Icons.fact_check_rounded, color: accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Parcours de verification',
                style: const TextStyle(
                  color: AppColors.darkText,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: stages.map((stage) {
              final active = stage.$2;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color:
                      active ? accent.withValues(alpha: 0.12) : palette.panel,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      active
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 15,
                      color: active ? accent : AppColors.darkMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      stage.$1,
                      style: TextStyle(
                        color: active ? accent : AppColors.darkMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Text(
            'Etat actuel: $statusLabel',
            style: const TextStyle(
              color: AppColors.darkMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatSubmittedAt(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final year = parsed.year.toString();
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '$day/$month/$year a $hour:$minute';
  }

  Widget _infoBand(String label, String value, Color valueColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MbongoThemeController.current.panelAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 74,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.darkMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reasonCard(String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B1018), Color(0xFF581722)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Motif de refus',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFFFD8DD),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumb(String label, File? file) {
    final palette = MbongoThemeController.current;
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
          height: 84,
          decoration: BoxDecoration(
            color: palette.panelAlt,
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
                  ),
                )
              : Image.file(file, fit: BoxFit.cover),
        ),
      ],
    );
  }
}
