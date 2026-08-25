import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/mbongo_theme.dart';
import '../services/api_service.dart';
import '../widgets/common/app_scaffold.dart';

class ForgotPinScreen extends StatefulWidget {
  final String initialPhone;
  const ForgotPinScreen({super.key, this.initialPhone = ''});

  @override
  State<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends State<ForgotPinScreen> {
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final otpCtrl = TextEditingController();
  final pinCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  // 0 = phone, 1 = otp, 2 = new pin
  int _step = 0;
  bool _loading = false;
  String? _testCode;
  String _sentVia = 'SMS';

  @override
  void initState() {
    super.initState();
    phoneCtrl.text = widget.initialPhone;
  }

  @override
  void dispose() {
    phoneCtrl.dispose();
    emailCtrl.dispose();
    otpCtrl.dispose();
    pinCtrl.dispose();
    confirmCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _sendOtp() async {
    final phone = phoneCtrl.text.trim();
    if (phone.isEmpty) { _snack('Entrez votre numéro.'); return; }
    setState(() => _loading = true);
    try {
      final email = emailCtrl.text.trim();
      final res = await ApiService.requestOtp(phone, purpose: 'reset', email: email.isNotEmpty ? email : null);
      if (!mounted) return;
      final via = res['via']?.toString() ?? '';
      setState(() {
        _testCode = res['code']?.toString();
        _sentVia = via.contains('email') && via.contains('sms')
            ? 'SMS et email'
            : via.contains('email')
                ? 'email'
                : 'SMS';
        _step = 1;
      });
    } catch (e) {
      if (mounted) _snack(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final code = otpCtrl.text.trim();
    if (code.length < 4) { _snack('Entrez le code reçu.'); return; }
    setState(() => _loading = true);
    try {
      final res = await ApiService.verifyOtp(phoneCtrl.text.trim(), code, purpose: 'reset');
      if (!mounted) return;
      if (res['valid'] == true) {
        setState(() => _step = 2);
      } else {
        _snack(res['reason']?.toString() ?? 'Code invalide.');
      }
    } catch (e) {
      if (mounted) _snack(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPin() async {
    final pin = pinCtrl.text.trim();
    final confirm = confirmCtrl.text.trim();
    if (pin.length < 4) { _snack('PIN trop court (min 4 chiffres).'); return; }
    if (pin != confirm) { _snack('Les codes PIN ne correspondent pas.'); return; }
    setState(() => _loading = true);
    try {
      await ApiService.resetPin(phoneCtrl.text.trim(), otpCtrl.text.trim(), pin);
      if (!mounted) return;
      _snack('Code PIN mis à jour avec succès.');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) _snack(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    final titles = ['Numéro de téléphone', 'Code de vérification', 'Nouveau code PIN'];
    final subs = [
      'Entrez votre numéro pour recevoir un code par SMS et/ou email.',
      'Entrez le code envoyé par $_sentVia au ${phoneCtrl.text}.',
      'Choisissez un nouveau code PIN.',
    ];

    return AppScaffold(
      title: 'Code PIN oublié',
      useParticles: true,
      particleDensity: 0.7,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_testCode != null && _step == 1)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.gold, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Mode TEST', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text('Code : $_testCode', style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 4)),
                ])),
              ]),
            ),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: palette.bannerGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(titles[_step], style: const TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(subs[_step], style: const TextStyle(color: AppColors.textSoft, fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
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
            child: Column(children: [
              if (_step == 0) ...[
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Numéro de téléphone', prefixIcon: Icon(Icons.phone_outlined)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email (optionnel)',
                    hintText: 'Pour recevoir le code par email aussi',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 18),
                _btn('Envoyer le code', _sendOtp),
              ] else if (_step == 1) ...[
                TextField(
                  controller: otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 6),
                  decoration: const InputDecoration(hintText: '— — — — — —', labelText: 'Code OTP', prefixIcon: Icon(Icons.sms_outlined), counterText: ''),
                ),
                const SizedBox(height: 18),
                _btn('Vérifier le code', _verifyOtp),
              ] else ...[
                TextField(
                  controller: pinCtrl,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Nouveau code PIN', prefixIcon: Icon(Icons.lock_outline)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmCtrl,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirmer le code PIN', prefixIcon: Icon(Icons.lock_outline)),
                ),
                const SizedBox(height: 18),
                _btn('Valider', _resetPin),
              ],
            ]),
          ),
        ],
      ),
    );
  }

  Widget _btn(String label, VoidCallback action) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: _loading ? null : action,
      child: _loading
          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : Text(label),
    ),
  );
}
