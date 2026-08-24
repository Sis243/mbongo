import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/mbongo_theme.dart';
import '../features/auth/presentation/auth_notifier.dart';
import '../widgets/common/app_scaffold.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  final String verificationId;
  final bool autoVerified;
  final String? testCode;
  final bool smsFailed;

  const OtpScreen({
    super.key,
    required this.phone,
    this.verificationId = '',
    this.autoVerified = false,
    this.testCode,
    this.smsFailed = false,
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final otpCtrl = TextEditingController();
  bool loading = false;

  Future<void> _verifyAndLogin() async {
    final code = otpCtrl.text.trim();
    if (code.length < 4) {
      _snack('Entrez le code de vérification reçu.');
      return;
    }
    setState(() => loading = true);
    try {
      await ref.read(authProvider.notifier).loginWithOtp(
        phone: widget.phone,
        code: code,
      );
      // GoRouter redirige automatiquement quand authProvider passe en AsyncData(user)
    } catch (e) {
      if (!mounted) return;
      _snack('Code invalide ou expiré. Renvoyez un nouveau code.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    final displayPhone = widget.phone.isEmpty ? '—' : widget.phone;

    return AppScaffold(
      title: 'Vérification OTP',
      useParticles: true,
      particleDensity: 0.85,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.smsFailed && widget.testCode == null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'SMS indisponible. Contactez le support Mbongo pour obtenir votre code.',
                      style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (widget.testCode != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.gold, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Mode TEST — code visible', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800, fontSize: 12)),
                        const SizedBox(height: 2),
                        Text('Code : ${widget.testCode}', style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: palette.bannerGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Code de vérification', style: TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text('Entrez le code envoyé au $displayPhone.', style: const TextStyle(color: AppColors.textSoft, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: palette.panelAlt,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
              boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 5))],
            ),
            child: Column(
              children: [
                TextField(
                  controller: otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  autofocus: true,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 8),
                  decoration: const InputDecoration(
                    hintText: '— — — — — —',
                    labelText: 'Code OTP (6 chiffres)',
                    prefixIcon: Icon(Icons.sms_outlined),
                    counterText: '',
                  ),
                  onSubmitted: (_) => _verifyAndLogin(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : _verifyAndLogin,
                    child: loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
                        : const Text('Se connecter'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.timer_outlined, color: AppColors.gold, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Le code est valable 5 minutes.', style: TextStyle(color: AppColors.textSoft, fontSize: 12.5, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
