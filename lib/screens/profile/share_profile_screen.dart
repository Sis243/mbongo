import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../features/auth/presentation/auth_notifier.dart';
import '../../services/api_service.dart';
import '../../widgets/common/mbongo_sub_app_bar.dart';
import '../transfer/qr_scanner_screen.dart';

class ShareProfileScreen extends ConsumerStatefulWidget {
  const ShareProfileScreen({super.key});

  @override
  ConsumerState<ShareProfileScreen> createState() => _ShareProfileScreenState();
}

class _ShareProfileScreenState extends ConsumerState<ShareProfileScreen> {
  QrRole _role = QrRole.client;
  String _agentCode = '';
  String _merchantId = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _detectRole();
  }

  Future<void> _detectRole() async {
    try {
      final log = await ApiService.getAgentProfitLog();
      final agentCode = log['agentCode']?.toString() ?? log['data']?['agentCode']?.toString();
      if (agentCode != null && agentCode.isNotEmpty) {
        if (mounted) setState(() { _role = QrRole.agent; _agentCode = agentCode; _loading = false; });
        return;
      }
    } catch (_) {}
    try {
      final profile = await ApiService.getMyMerchantProfile();
      final mid = profile['id']?.toString() ?? '';
      if (mid.isNotEmpty && mounted) {
        setState(() { _role = QrRole.merchant; _merchantId = mid; _loading = false; });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() { _role = QrRole.client; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    final user = ref.watch(authProvider).valueOrNull;
    final name = user?.name ?? '';
    final phone = user?.phone ?? '';

    final qrData = QrScanResult.buildLink(
      phone: phone,
      name: name,
      role: _role,
      agentCode: _agentCode.isNotEmpty ? _agentCode : null,
      merchantId: _merchantId.isNotEmpty ? _merchantId : null,
    );

    final roleLabel = switch (_role) {
      QrRole.agent => 'Agent MBONGO',
      QrRole.merchant => 'Marchand MBONGO',
      _ => 'Client MBONGO',
    };

    final roleColor = switch (_role) {
      QrRole.agent => AppColors.orange,
      QrRole.merchant => AppColors.green,
      _ => palette.accent,
    };

    final roleIcon = switch (_role) {
      QrRole.agent => Icons.support_agent_rounded,
      QrRole.merchant => Icons.storefront_rounded,
      _ => Icons.person_rounded,
    };

    final shareMessage = switch (_role) {
      QrRole.agent => 'Déposez de l\'argent sur MBONGO via mon agence !\nNom : $name\nTéléphone : $phone\nCode agent : $_agentCode',
      QrRole.merchant => 'Payez votre achat via MBONGO !\nMarchand : $name\nTéléphone : $phone',
      _ => 'Envoyez-moi de l\'argent via MBONGO !\nNom : $name\nTéléphone : $phone',
    };

    return Scaffold(
      backgroundColor: palette.shellBottom,
      appBar: MbongoSubAppBar(title: 'Mon QR de paiement'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.shellTop, palette.shellBottom],
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // ── Header profil ────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: palette.bannerGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [BoxShadow(color: palette.glow.withValues(alpha: 0.22), blurRadius: 18, offset: const Offset(0, 8))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56, height: 56,
                              decoration: BoxDecoration(
                                color: roleColor.withValues(alpha: 0.25),
                                shape: BoxShape.circle,
                                border: Border.all(color: roleColor.withValues(alpha: 0.5)),
                              ),
                              child: Icon(roleIcon, color: roleColor, size: 26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                                const SizedBox(height: 3),
                                Text(phone, style: const TextStyle(color: Color(0xFFD0DDEE), fontSize: 13)),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(8)),
                                  child: Text(roleLabel, style: TextStyle(color: roleColor, fontSize: 11, fontWeight: FontWeight.w900)),
                                ),
                              ]),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── QR Code ─────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 8))],
                        ),
                        child: Column(
                          children: [
                            QrImageView(
                              data: qrData,
                              version: QrVersions.auto,
                              size: 220,
                              backgroundColor: Colors.white,
                              eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: const Color(0xFF0D1B2A)),
                              dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: const Color(0xFF0D1B2A)),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              switch (_role) {
                                QrRole.agent => 'Les clients scannent pour déposer',
                                QrRole.merchant => 'Les clients scannent pour payer',
                                _ => 'Faites scanner pour recevoir de l\'argent',
                              },
                              style: const TextStyle(color: Color(0xFF3A4A5C), fontSize: 13, fontWeight: FontWeight.w700),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Info rôle ────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: roleColor.withValues(alpha: 0.2)),
                        ),
                        child: Row(children: [
                          Icon(Icons.info_outline_rounded, color: roleColor, size: 16),
                          const SizedBox(width: 10),
                          Expanded(child: Text(
                            switch (_role) {
                              QrRole.agent => 'Quand un client scanne ce QR, l\'app ouvre directement le formulaire de dépôt avec votre agence pré-sélectionnée.',
                              QrRole.merchant => 'Quand un client scanne, l\'app ouvre le formulaire de paiement marchand avec votre commerce pré-rempli.',
                              _ => 'Quand quelqu\'un scanne ce QR, l\'app ouvre directement le formulaire de virement avec votre numéro pré-rempli.',
                            },
                            style: TextStyle(color: roleColor, fontSize: 12, height: 1.4),
                          )),
                        ]),
                      ),
                      const SizedBox(height: 20),

                      // ── Boutons ──────────────────────────────────────────
                      Row(children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            label: const Text('Copier numéro'),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: phone));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Numéro copié')),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.share_rounded, size: 16),
                            label: const Text('Partager'),
                            onPressed: () => Share.share(shareMessage, subject: 'Mon profil MBONGO'),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
