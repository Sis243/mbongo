import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/mbongo_theme.dart';
import '../services/auth_service.dart';
import '../widgets/common/mbongo_money_particles.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      icon: Icons.account_balance_wallet_rounded,
      title: 'Votre argent,\npartout',
      body:
          'Envoyez et recevez de l\'argent en CDF ou USD depuis votre téléphone, en toute sécurité, 24h/24.',
    ),
    _Slide(
      icon: Icons.flash_on_rounded,
      title: 'Paiements\nen un clic',
      body:
          'Rechargez votre airtime, payez votre abonnement TV, règlez vos factures et achetez chez les marchands.',
    ),
    _Slide(
      icon: Icons.shield_rounded,
      title: 'Sécurité\nmaximale',
      body:
          'PIN chiffré, biométrie, vérification KYC et alertes en temps réel pour protéger chaque transaction.',
    ),
  ];

  void _next() {
    HapticFeedback.lightImpact();
    if (_page < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await AuthService.setSeenOnboarding();
    if (!mounted) return;
    context.go('/auth/register');
  }

  Future<void> _login() async {
    await AuthService.setSeenOnboarding();
    if (!mounted) return;
    context.go('/auth/login');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    final isLast = _page == _slides.length - 1;

    return Scaffold(
      backgroundColor: palette.shellBottom,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [palette.shellTop, palette.shellBottom],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: MbongoMoneyParticles(
                color: palette.accentStrong,
                count: 20,
                opacity: 0.10,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Logo + skip
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Image.asset('assets/images/mbongo_logo.png', width: 36),
                      const SizedBox(width: 10),
                      Text(
                        'MBONGO',
                        style: TextStyle(
                          color: palette.accent,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      if (!isLast)
                        TextButton(
                          onPressed: _login,
                          child: const Text(
                            'J\'ai un compte',
                            style: TextStyle(
                              color: AppColors.textSoft,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Slides
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemCount: _slides.length,
                    itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
                  ),
                ),

                // Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (i) {
                    final active = i == _page;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active
                            ? palette.accent
                            : AppColors.border.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),

                // Buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _next,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: palette.accentStrong,
                            padding:
                                const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            isLast ? 'Ouvrir mon compte' : 'Suivant',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _login,
                        child: const Text(
                          'J\'ai déjà un compte — Se connecter',
                          style: TextStyle(
                            color: AppColors.textSoft,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Slide data ────────────────────────────────────────────────────────────────

class _Slide {
  final IconData icon;
  final String title;
  final String body;
  const _Slide({required this.icon, required this.title, required this.body});
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon circle
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: palette.bannerGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: palette.glow.withValues(alpha: 0.30),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(slide.icon, color: Colors.white, size: 62),
          ),
          const SizedBox(height: 42),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSoft,
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
