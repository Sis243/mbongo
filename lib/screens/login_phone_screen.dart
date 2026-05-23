import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/mbongo_theme.dart';
import '../core/storage/app_storage.dart';
import '../features/auth/presentation/auth_notifier.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../widgets/common/mbongo_money_particles.dart';
import '../widgets/common/mbongo_sub_app_bar.dart';
import 'otp_screen.dart';

class LoginPhoneScreen extends ConsumerStatefulWidget {
  const LoginPhoneScreen({super.key});

  @override
  ConsumerState<LoginPhoneScreen> createState() => _LoginPhoneScreenState();
}

class _LoginPhoneScreenState extends ConsumerState<LoginPhoneScreen> {
  final phoneCtrl = TextEditingController(text: '');
  bool loading = false;
  bool biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final enabled = await AuthService.isBiometricEnabled();
    if (!enabled) return;
    final creds = await AppStorage().getBioCredentials();
    final canCheck = await BiometricService.canCheck();
    if (canCheck && creds.phone != null && creds.pin != null && mounted) {
      setState(() => biometricAvailable = true);
    }
  }

  Future<void> _loginWithBiometrics() async {
    final authenticated = await BiometricService.authenticate();
    if (!authenticated || !mounted) return;

    final creds = await AppStorage().getBioCredentials();
    if (creds.phone == null || creds.pin == null) return;

    setState(() => loading = true);
    try {
      await ref.read(authProvider.notifier).login(
            phone: creds.phone!,
            pin: creds.pin!,
          );
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> sendOtp() async {
    final phone = phoneCtrl.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrez votre numéro de téléphone.')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      final result = await ApiService.requestOtp(phone, purpose: 'login');
      final testCode = result['code'] as String?;
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            phone: phone,
            verificationId: 'MBONGO-OTP',
            testCode: testCode,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: MbongoSubAppBar(title: 'Connexion OTP'),
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
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: palette.bannerGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connexion OTP',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Un code de vérification sera généré pour votre numéro.',
                      style: TextStyle(
                        color: AppColors.textSoft,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _tag('Vérification en 2 étapes'),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: palette.panelAlt,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.24),
                  ),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone',
                        hintText: '0990000000',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loading ? null : sendOtp,
                        child: loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.4),
                              )
                            : const Text('Recevoir le code'),
                      ),
                    ),
                    if (biometricAvailable) ...[
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text('ou', style: TextStyle(color: AppColors.textSoft)),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: loading ? null : _loginWithBiometrics,
                          icon: const Icon(Icons.fingerprint_rounded),
                          label: const Text('Connexion biométrique'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.cyan,
                            side: const BorderSide(color: AppColors.cyan),
                          ),
                        ),
                      ),
                    ],
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
                      child: Text(
                        'Le code est valable 5 minutes.',
                        style: TextStyle(
                          color: AppColors.textSoft,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
