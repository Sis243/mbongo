import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/mbongo_theme.dart';
import '../widgets/common/mbongo_money_particles.dart';
import '../widgets/primary_button.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    return Scaffold(
      backgroundColor: palette.shellBottom,
      body: Stack(
        children: [
          Positioned.fill(
            child: MbongoMoneyParticles(
              color: palette.accentStrong,
              count: 20,
              opacity: 0.11,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [palette.shellTop, palette.shellBottom],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.center,
                      child: Image.asset('assets/images/mbongo_logo.png', width: 96),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'MBONGO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'La banque mobile\ndes Congolais.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSoft,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: palette.bannerGradient
                              .map((color) => color.withValues(alpha: 0.18))
                              .toList(),
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: const Text(
                        'Envoyez, recevez et gerez votre argent en CDF ou USD, depuis votre telephone, en toute securite.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSoft,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const Spacer(),
                    PrimaryButton(
                      label: 'Ouvrir mon compte',
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Text(
                        "J'ai deja un compte",
                        style: TextStyle(
                          color: AppColors.textSoft,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
