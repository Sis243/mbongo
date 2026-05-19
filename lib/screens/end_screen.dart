import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/mbongo_theme.dart';
import '../widgets/common/mbongo_money_particles.dart';
import '../widgets/primary_button.dart';
import 'main_shell.dart';

class EndScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const EndScreen({
    super.key,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    return Scaffold(
      backgroundColor: palette.shellBottom,
      body: Stack(
        children: [
          Positioned.fill(
            child: MbongoMoneyParticles(
              color: palette.accent,
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
                    const Spacer(),
                    Image.asset('assets/images/mbongo_logo.png', width: 110),
                    const SizedBox(height: 14),
                    const Text(
                      'MBONGO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Transaction effectuee',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Merci de nous avoir fait confiance.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: palette.accentStrong,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: palette.bannerGradient
                              .map((color) => color.withValues(alpha: 0.16))
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
                        'Votre operation a bien ete prise en compte. Vous pouvez revenir sur votre espace principal pour poursuivre.',
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
                      label: "Retour a l'accueil",
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MainShell(),
                          ),
                          (r) => false,
                        );
                      },
                    ),
                    const SizedBox(height: 10),
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
