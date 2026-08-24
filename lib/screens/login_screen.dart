import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/app_storage.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/phone_validator.dart';
import '../core/theme/mbongo_theme.dart';
import '../features/auth/presentation/auth_notifier.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../widgets/common/mbongo_money_particles.dart';
import 'forgot_pin_screen.dart';
import 'login_phone_screen.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final phoneCtrl = TextEditingController();
  final pinCtrl = TextEditingController();

  bool hidePin = true;
  bool loading = false;

  // Biometric state
  bool bioAvailable = false;
  bool bioEnabled = false;
  String bioLabel = 'Biometrie';

  // Mode: 'pin' shows the full form; 'bio' shows biometric prompt
  bool showPinFallback = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storage = AppStorage();
    final lastPhone = await storage.getLastPhone();
    final bioEnabledPref = await AuthService.isBiometricEnabled();
    final bioOk = await BiometricService.canCheck();
    final creds = await storage.getBioCredentials();
    final hasBioCreds = creds.phone != null && creds.phone!.isNotEmpty &&
        creds.pin != null && creds.pin!.isNotEmpty;
    final label = await BiometricService.securityLabel();

    if (!mounted) return;
    setState(() {
      if (lastPhone != null && lastPhone.isNotEmpty) phoneCtrl.text = lastPhone;
      bioAvailable = bioOk;
      bioEnabled = bioEnabledPref && bioOk && hasBioCreds;
      bioLabel = label;
      showPinFallback = !bioEnabled;
    });

    if (bioEnabled) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) _triggerBiometric();
    }
  }

  Future<void> _triggerBiometric() async {
    final storage = AppStorage();
    final creds = await storage.getBioCredentials();
    if (creds.phone == null || creds.pin == null) return;

    final ok = await BiometricService.authenticate();
    if (!ok || !mounted) return;

    setState(() => loading = true);
    try {
      await ref.read(authProvider.notifier).login(
        phone: creds.phone!,
        pin: creds.pin!,
      );
    } catch (_) {
      if (!mounted) return;
      // Credentials may have changed — clear bio and show PIN form
      await storage.clearBioCredentials();
      await AuthService.setBiometricEnabled(false);
      setState(() {
        bioEnabled = false;
        showPinFallback = true;
        loading = false;
      });
      _toast('Session expirée. Reconnectez-vous avec votre PIN.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _loginWithPin() async {
    final phone = PhoneValidator.normalize(phoneCtrl.text);
    final pin = pinCtrl.text.trim();
    if (pin.isEmpty) { _toast('Entrez votre code PIN.'); return; }
    final phoneError = PhoneValidator.errorMessage(phone);
    if (phoneError != null) { _toast(phoneError); return; }

    setState(() => loading = true);
    try {
      await ref.read(authProvider.notifier).login(phone: phone, pin: pin);
      await AppStorage().saveLastPhone(phone);
      if (!mounted) return;
      _maybeOfferBiometric(phone, pin);
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      _toast('Numéro ou code PIN incorrect.');
    }
  }

  Future<void> _maybeOfferBiometric(String phone, String pin) async {
    if (!bioAvailable) return;
    final alreadyEnabled = await AuthService.isBiometricEnabled();
    if (alreadyEnabled) return;

    if (!mounted) return;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MbongoThemeController.current.panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.fingerprint_rounded, color: AppColors.gold, size: 26),
            const SizedBox(width: 10),
            const Text('Connexion rapide', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w900, fontSize: 17)),
          ],
        ),
        content: Text(
          'Activer la connexion par $bioLabel pour ne plus taper votre PIN ?',
          style: const TextStyle(color: AppColors.textSoft, fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Pas maintenant')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Activer')),
        ],
      ),
    );

    if (accepted == true) {
      await AppStorage().saveBioCredentials(phone, pin);
      await AuthService.setBiometricEnabled(true);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    phoneCtrl.dispose();
    pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: MbongoMoneyParticles(
                color: palette.accent,
                count: 18,
                opacity: 0.09,
                height: 0,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [palette.shellTop, palette.shellBottom],
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
              children: [
                _buildHero(palette),
                const SizedBox(height: 24),
                if (bioEnabled && !showPinFallback)
                  _buildBiometricPanel(palette)
                else
                  _buildPinPanel(palette),
                const SizedBox(height: 18),
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(MbongoThemePalette palette) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            palette.bannerGradient.first.withValues(alpha: 0.95),
            palette.bannerGradient.last.withValues(alpha: 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: palette.glow.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: Image.asset('assets/icon/mbongo.png', fit: BoxFit.contain),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MBONGO', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                SizedBox(height: 4),
                Text('Accédez à votre compte', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricPanel(MbongoThemePalette palette) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: palette.glow.withValues(alpha: 0.14), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: loading ? null : _triggerBiometric,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.glow.withValues(alpha: 0.12),
                border: Border.all(color: palette.accent.withValues(alpha: 0.5), width: 2),
              ),
              child: loading
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Icon(Icons.fingerprint_rounded, size: 52, color: palette.accent),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            bioLabel,
            style: TextStyle(color: palette.accent, fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Appuyez pour vous identifier',
            style: TextStyle(color: AppColors.textSoft, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 22),
          TextButton.icon(
            onPressed: () => setState(() => showPinFallback = true),
            icon: const Icon(Icons.lock_outline_rounded, size: 16),
            label: const Text('Utiliser le code PIN'),
            style: TextButton.styleFrom(foregroundColor: AppColors.textSoft),
          ),
        ],
      ),
    );
  }

  Widget _buildPinPanel(MbongoThemePalette palette) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: palette.glow.withValues(alpha: 0.14), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Connexion',
                  style: TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPhoneScreen())),
                child: const Text('Code SMS'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Numéro de téléphone',
              hintText: '0812345678',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: pinCtrl,
            obscureText: hidePin,
            keyboardType: TextInputType.number,
            onSubmitted: (_) => _loginWithPin(),
            decoration: InputDecoration(
              labelText: 'Code PIN',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () => setState(() => hidePin = !hidePin),
                icon: Icon(hidePin ? Icons.visibility_off_rounded : Icons.visibility_rounded),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: loading ? null : _loginWithPin,
              child: loading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4))
                  : const Text('Se connecter'),
            ),
          ),
          if (bioEnabled) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => setState(() => showPinFallback = false),
                icon: const Icon(Icons.fingerprint_rounded),
                label: Text('Retour $bioLabel'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ForgotPinScreen(initialPhone: phoneCtrl.text.trim())),
          ),
          child: const Text('Code PIN oublié ?'),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
          ),
          child: const Text("Pas encore de compte ? S'inscrire"),
        ),
      ],
    );
  }
}
