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
  bool biometricAvailable = false;
  bool biometricEnabled = false;
  bool faceRecognitionEnabled = false;
  String selectedLanguage = 'Francais';

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final available = await BiometricService.canCheck();
    final enabled = await AuthService.isBiometricEnabled();
    final faceEnabled = await AuthService.isFaceRecognitionEnabled();
    final language = await AuthService.getSelectedLanguage();

    if (!mounted) return;
    setState(() {
      biometricAvailable = available;
      biometricEnabled = enabled;
      faceRecognitionEnabled = faceEnabled;
      selectedLanguage = language;
    });

    // Auto-trigger biometric if enabled and credentials are stored
    if (available && enabled) {
      final creds = await AppStorage().getBioCredentials();
      if (creds.phone != null && creds.phone!.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) loginWithBiometric();
      }
    }
  }

  Future<void> login() async {
    final phone = PhoneValidator.normalize(phoneCtrl.text);
    final pin = pinCtrl.text.trim();

    if (pin.isEmpty) {
      _toast('Veuillez entrer votre code PIN.');
      return;
    }
    final phoneError = PhoneValidator.errorMessage(phone);
    if (phoneError != null) {
      _toast(phoneError);
      return;
    }

    setState(() => loading = true);
    try {
      await ref
          .read(authProvider.notifier)
          .login(phone: phone, pin: pin);
      await AuthService.setBiometricEnabled(biometricEnabled);
      if (biometricEnabled) {
        await AppStorage().saveBioCredentials(phone, pin);
      } else {
        await AppStorage().clearBioCredentials();
      }
      if (!mounted) return;
      // Le router redirige automatiquement vers /home grâce au changement d'état auth
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      _toast('Numéro ou code PIN incorrect. Vérifiez vos informations.');
    }
  }

  Future<void> loginWithBiometric() async {
    // Vérifier que des credentials sont stockés avant de déclencher le capteur
    final creds = await AppStorage().getBioCredentials();
    if (creds.phone == null || creds.phone!.isEmpty ||
        creds.pin == null || creds.pin!.isEmpty) {
      if (mounted) _toast('Activez d\'abord la biométrie en vous connectant avec votre PIN.');
      return;
    }

    final ok = await BiometricService.authenticate();
    if (!ok) {
      if (mounted) _toast('Authentification biométrique annulée ou échouée. Utilisez votre PIN.');
      return;
    }

    if (!mounted) return;
    setState(() => loading = true);
    try {
      await ref.read(authProvider.notifier).login(
        phone: creds.phone!,
        pin: creds.pin!,
      );
      // Pas de context.go ici — GoRouter redirige automatiquement
      // quand authProvider passe en AsyncData(user)
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
      // Le PIN stocké ne correspond plus — on vide les credentials biométriques
      await AppStorage().clearBioCredentials();
      await AuthService.setBiometricEnabled(false);
      _toast('PIN modifié ou session expirée. Reconnectez-vous avec votre PIN pour réactiver la biométrie.');
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
                count: 22,
                opacity: 0.1,
                height: 0,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  palette.shellTop,
                  palette.shellBottom,
                ],
              ),
            ),
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
            children: [
              _hero(palette),
              const SizedBox(height: 18),
              _securityStrip(),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: palette.panel,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: palette.glow.withValues(alpha: 0.16),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Connexion securisee',
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginPhoneScreen(),
                              ),
                            );
                          },
                          child: const Text('Connexion OTP'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Entrez votre numero et votre code PIN',
                      style: TextStyle(
                        color: AppColors.textSoft,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
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
                      decoration: InputDecoration(
                        labelText: 'Code PIN',
                        hintText: '4 chiffres minimum',
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
                    if (biometricAvailable) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: palette.accent.withValues(alpha: 0.18),
                          ),
                        ),
                        child: CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: biometricEnabled,
                          onChanged: (value) {
                            setState(() => biometricEnabled = value ?? false);
                          },
                          activeColor: AppColors.cyan,
                          title: const Text(
                            'Activer la biometrie',
                            style: TextStyle(
                              color: AppColors.text,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: const Text(
                            'Connexion rapide au prochain demarrage',
                            style: TextStyle(
                              color: AppColors.textSoft,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loading ? null : login,
                        child: loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.4),
                              )
                            : const Text('Se connecter'),
                      ),
                    ),
                    if (biometricAvailable) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: loginWithBiometric,
                          icon: const Icon(Icons.fingerprint_rounded),
                          label: const Text('Connexion par empreinte'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _footerLinks(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hero(MbongoThemePalette palette) {
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
            color: palette.glow.withValues(alpha: 0.24),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    'assets/icon/mbongo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  selectedLanguage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'MBONGO',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bienvenue sur MBONGO',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Acces a votre compte en toute securite.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13.2,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _securityStrip() {
    return Row(
      children: [
        Expanded(
          child: _miniSignal(
            'Biometrie',
            biometricAvailable ? 'Disponible' : 'Non disponible',
            biometricAvailable ? AppColors.green : AppColors.orange,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _miniSignal(
            'Securite',
            'Connexion chiffree',
            AppColors.cyan,
          ),
        ),
      ],
    );
  }

  Widget _miniSignal(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSoft,
              fontSize: 12,
              fontWeight: FontWeight.w700,
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

  Widget _footerLinks(BuildContext context) {
    return Column(
      children: [
        TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ForgotPinScreen(initialPhone: phoneCtrl.text.trim()))),
          child: const Text('Code PIN oublie ?'),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0C2044), Color(0xFF102A55)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.8),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pas encore de compte ?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.cyan,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: const Text(
                  'Creer un compte',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
