import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../features/auth/presentation/auth_notifier.dart';
import '../../widgets/common/mbongo_money_particles.dart';
import '../../widgets/common/mbongo_sub_app_bar.dart';

class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  bool _codeCopied = false;
  bool _linkCopied = false;

  String _referralCode(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9]'), '').substring(
          (phone.replaceAll(RegExp(r'[^0-9]'), '').length - 6)
              .clamp(0, phone.replaceAll(RegExp(r'[^0-9]'), '').length),
        );
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    setState(() => _codeCopied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _codeCopied = false);
  }

  Future<void> _copyLink(String link) async {
    await Clipboard.setData(ClipboardData(text: link));
    setState(() => _linkCopied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _linkCopied = false);
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    final user = ref.watch(authProvider).valueOrNull;
    final phone = user?.phone ?? '';
    final name = user?.name ?? 'Utilisateur';
    final code = _referralCode(phone);
    final link = 'https://mbongo.app/register?ref=$code&name=${Uri.encodeComponent(name)}';

    return Scaffold(
      backgroundColor: palette.shellBottom,
      appBar: MbongoSubAppBar(title: 'Parrainage'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.shellTop, palette.shellBottom],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: MbongoMoneyParticles(
                  color: palette.accent,
                  count: 14,
                  opacity: 0.08,
                  height: 0,
                ),
              ),
            ),
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeaderCard(palette),
                  const SizedBox(height: 18),
                  _buildCodeCard(palette, code),
                  const SizedBox(height: 14),
                  _buildLinkCard(palette, link),
                  const SizedBox(height: 18),
                  _buildHowItWorksCard(palette),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: () => _copyLink(link),
                    icon: Icon(_linkCopied ? Icons.check_rounded : Icons.share_rounded),
                    label: Text(_linkCopied ? 'Lien copie !' : 'Partager mon lien'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _linkCopied ? AppColors.green : palette.accentStrong,
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

  Widget _buildHeaderCard(MbongoThemePalette palette) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette.bannerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
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
              Icon(Icons.group_add_rounded, color: palette.accentStrong),
              const SizedBox(width: 8),
              const Text(
                'Programme de parrainage',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Invitez vos proches',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Partagez votre code de parrainage unique et invitez vos amis et votre famille a rejoindre MBONGO. Ensemble, simplifions vos finances !',
            style: TextStyle(
              color: Color(0xFFE8EEF8),
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeCard(MbongoThemePalette palette, String code) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.accent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: palette.glow.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.confirmation_number_outlined, color: palette.accent),
              const SizedBox(width: 8),
              const Text(
                'Votre code de parrainage',
                style: TextStyle(color: AppColors.darkText, fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFF102A55),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.accent.withValues(alpha: 0.5)),
            ),
            child: Text(
              code,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.accent,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _copyCode(code),
              icon: Icon(
                _codeCopied ? Icons.check_rounded : Icons.copy_rounded,
                size: 18,
              ),
              label: Text(_codeCopied ? 'Code copie !' : 'Copier le code'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _codeCopied ? AppColors.green : palette.accent,
                side: BorderSide(
                  color: _codeCopied ? AppColors.green : palette.accent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkCard(MbongoThemePalette palette, String link) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lien de parrainage',
                  style: TextStyle(
                    color: AppColors.darkMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  link,
                  style: TextStyle(
                    color: palette.accent,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _copyLink(link),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: palette.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _linkCopied ? Icons.check_rounded : Icons.copy_rounded,
                  color: _linkCopied ? AppColors.green : palette.accent,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksCard(MbongoThemePalette palette) {
    final steps = [
      (Icons.share_rounded, 'Partagez', 'Envoyez votre code ou lien a vos proches via WhatsApp, SMS ou email.'),
      (Icons.person_add_rounded, 'Inscription', 'Votre filleul s\'inscrit sur MBONGO en utilisant votre code.'),
      (Icons.check_circle_rounded, 'Activation', 'Le compte de votre filleul est verifie et actif.'),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 14, offset: Offset(0, 7)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: palette.accent),
              const SizedBox(width: 8),
              const Text(
                'Comment ca marche ?',
                style: TextStyle(color: AppColors.darkText, fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((e) {
            final i = e.key;
            final (icon, title, desc) = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: palette.accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: palette.accent, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${i + 1}. $title',
                          style: const TextStyle(
                            color: AppColors.darkText,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          desc,
                          style: const TextStyle(
                            color: AppColors.darkMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
