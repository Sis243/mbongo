import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/mbongo_theme.dart';
import '../services/auth_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _page = 0;
  late final AnimationController _illustAnim;
  late final AnimationController _bgAnim;

  static const _slides = [
    _Slide(
      type: _IllustType.welcome,
      overline: 'Bienvenue sur Mbongo',
      title: 'Votre argent,\nvotre liberté',
      body: 'La banque mobile CADECO au bout de vos doigts — gérez vos finances en CDF et USD, partout en RDC, 24 h/24.',
    ),
    _Slide(
      type: _IllustType.account,
      overline: 'Inscription simple',
      title: 'Ouvert en\n5 minutes',
      body: 'Un numéro de téléphone suffit pour créer votre compte. Vérification KYC rapide, zéro paperasse.',
    ),
    _Slide(
      type: _IllustType.transfer,
      overline: 'Transferts instantanés',
      title: 'Envoyez\npartout au Congo',
      body: 'CDF ou USD vers n\'importe quel numéro mobile — vos proches reçoivent en quelques secondes.',
    ),
    _Slide(
      type: _IllustType.payments,
      overline: 'Tout en un',
      title: 'Payez toutes\nvos factures',
      body: 'Airtime, eau, électricité, câble TV, paiement marchand par QR — une seule appli pour tout.',
    ),
    _Slide(
      type: _IllustType.security,
      overline: 'Zéro compromis',
      title: 'Sécurité\nde niveau bancaire',
      body: 'PIN chiffré, biométrie, alertes SMS en temps réel et vérification KYC pour chaque transaction.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _illustAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..forward();
    _bgAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _illustAnim.dispose();
    _bgAnim.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _goTo(int i) {
    HapticFeedback.selectionClick();
    _pageCtrl.animateToPage(
      i,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
  }

  void _next() {
    HapticFeedback.lightImpact();
    if (_page < _slides.length - 1) {
      _goTo(_page + 1);
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

  void _onPageChanged(int i) {
    setState(() => _page = i);
    _illustAnim
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    final isDark = MbongoThemeController.darkModeEnabled.value;
    final isLast = _page == _slides.length - 1;

    final titleColor = isDark ? Colors.white : AppColors.lightText;
    final bodyColor = isDark
        ? Colors.white.withValues(alpha: 0.65)
        : AppColors.lightSoft;
    final overlineColor = palette.accent;
    final skipColor = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : AppColors.lightMuted;

    final bgTop = isDark
        ? const Color(0xFF0A0E1A)
        : const Color(0xFFF0F4FF);
    final bgBottom = isDark
        ? const Color(0xFF111827)
        : const Color(0xFFFFFFFF);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: AnimatedBuilder(
          animation: _bgAnim,
          builder: (_, __) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [bgTop, bgBottom],
                  stops: const [0.0, 1.0],
                ),
              ),
              child: SafeArea(
                child: Stack(
                  children: [
                    // Ambient background glow — shifts slowly with bgAnim
                    Positioned(
                      top: -80 + _bgAnim.value * 40,
                      left: -60 + _bgAnim.value * 30,
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              palette.accentStrong.withValues(alpha: isDark ? 0.12 : 0.06),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 60 - _bgAnim.value * 25,
                      right: -40 + _bgAnim.value * 20,
                      child: Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              palette.accent.withValues(alpha: isDark ? 0.08 : 0.05),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Main content
                    Column(
                      children: [
                        // ── Top bar ──────────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(22, 14, 16, 0),
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/images/mbongo_logo.png',
                                width: 34,
                                height: 34,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 9),
                              Text(
                                'MBONGO',
                                style: TextStyle(
                                  color: palette.accent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const Spacer(),
                              if (!isLast)
                                GestureDetector(
                                  onTap: _login,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: skipColor.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Text(
                                      'Connexion',
                                      style: TextStyle(
                                        color: skipColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // ── Slides ─────────────────────────────────────
                        Expanded(
                          child: PageView.builder(
                            controller: _pageCtrl,
                            onPageChanged: _onPageChanged,
                            itemCount: _slides.length,
                            itemBuilder: (_, i) => _SlideView(
                              slide: _slides[i],
                              illustAnim: _illustAnim,
                              isDark: isDark,
                              palette: palette,
                              titleColor: titleColor,
                              bodyColor: bodyColor,
                              overlineColor: overlineColor,
                            ),
                          ),
                        ),

                        // ── Bottom nav ─────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                          child: Column(
                            children: [
                              // Progress dots
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(_slides.length, (i) {
                                  final active = i == _page;
                                  return GestureDetector(
                                    onTap: () => _goTo(i),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeOutCubic,
                                      margin: const EdgeInsets.symmetric(horizontal: 3.5),
                                      width: active ? 28 : 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: active
                                            ? palette.accentStrong
                                            : (isDark
                                                ? Colors.white.withValues(alpha: 0.18)
                                                : const Color(0xFFCBD5E1)),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 24),

                              // CTA button
                              SizedBox(
                                width: double.infinity,
                                height: 58,
                                child: ElevatedButton(
                                  onPressed: _next,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: palette.accentStrong,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shadowColor: palette.accentStrong.withValues(alpha: 0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ).copyWith(
                                    elevation: WidgetStateProperty.resolveWith((s) =>
                                        s.contains(WidgetState.pressed) ? 0 : 4),
                                    shadowColor: WidgetStateProperty.all(
                                        palette.accentStrong.withValues(alpha: 0.35)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        isLast ? 'Ouvrir mon compte' : 'Continuer',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      if (!isLast) ...[
                                        const SizedBox(width: 8),
                                        const Icon(Icons.arrow_forward_rounded, size: 18),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Login link
                              GestureDetector(
                                onTap: _login,
                                child: Text(
                                  'Déjà inscrit ? Se connecter',
                                  style: TextStyle(
                                    color: palette.accent,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                    decorationColor: palette.accent.withValues(alpha: 0.4),
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
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Slide data ──────────────────────────────────────────────────────────────

enum _IllustType { welcome, account, transfer, payments, security }

class _Slide {
  final _IllustType type;
  final String overline;
  final String title;
  final String body;
  const _Slide({
    required this.type,
    required this.overline,
    required this.title,
    required this.body,
  });
}

// ── Slide view ──────────────────────────────────────────────────────────────

class _SlideView extends StatelessWidget {
  final _Slide slide;
  final AnimationController illustAnim;
  final bool isDark;
  final MbongoThemePalette palette;
  final Color titleColor;
  final Color bodyColor;
  final Color overlineColor;

  const _SlideView({
    required this.slide,
    required this.illustAnim,
    required this.isDark,
    required this.palette,
    required this.titleColor,
    required this.bodyColor,
    required this.overlineColor,
  });

  @override
  Widget build(BuildContext context) {
    final slideUp = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: illustAnim,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    ));
    final fade = CurvedAnimation(
      parent: illustAnim,
      curve: const Interval(0.0, 0.55, curve: Curves.easeIn),
    );
    final textSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: illustAnim,
      curve: const Interval(0.30, 1.0, curve: Curves.easeOutCubic),
    ));
    final textFade = CurvedAnimation(
      parent: illustAnim,
      curve: const Interval(0.30, 1.0, curve: Curves.easeOut),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: slideUp,
              child: _Illustration(
                type: slide.type,
                palette: palette,
                isDark: isDark,
              ),
            ),
          ),
          const SizedBox(height: 48),

          // Text block
          FadeTransition(
            opacity: textFade,
            child: SlideTransition(
              position: textSlide,
              child: Column(
                children: [
                  // Overline chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: overlineColor.withValues(alpha: isDark ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      slide.overline.toUpperCase(),
                      style: TextStyle(
                        color: overlineColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Title
                  Text(
                    slide.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 33,
                      fontWeight: FontWeight.w900,
                      height: 1.16,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Body
                  Text(
                    slide.body,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: bodyColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.65,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Illustrations ────────────────────────────────────────────────────────────

class _Illustration extends StatelessWidget {
  final _IllustType type;
  final MbongoThemePalette palette;
  final bool isDark;

  const _Illustration({
    required this.type,
    required this.palette,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (type == _IllustType.welcome) {
      return _WelcomeIllustration(palette: palette, isDark: isDark);
    }
    return _IconIllustration(type: type, palette: palette, isDark: isDark);
  }
}

// ── Slide 1: Vrai logo centré + badge CADECO ─────────────────────────────────

class _WelcomeIllustration extends StatelessWidget {
  final MbongoThemePalette palette;
  final bool isDark;
  const _WelcomeIllustration({required this.palette, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  palette.accentStrong.withValues(alpha: isDark ? 0.16 : 0.09),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Mid ring
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: palette.accent.withValues(alpha: isDark ? 0.12 : 0.08),
                width: 1,
              ),
            ),
          ),
          // Main circle
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  palette.bannerGradient[0].withValues(alpha: isDark ? 0.92 : 1.0),
                  palette.bannerGradient.last.withValues(alpha: isDark ? 0.88 : 0.95),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: palette.accentStrong.withValues(alpha: isDark ? 0.40 : 0.28),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Image.asset(
                'assets/images/mbongo_logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          // CADECO badge — bottom right
          Positioned(
            bottom: 16,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2533) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: palette.accent.withValues(alpha: 0.25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_rounded, color: palette.accent, size: 13),
                  const SizedBox(width: 5),
                  Text(
                    'CADECO',
                    style: TextStyle(
                      color: palette.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // RDC badge — top left
          Positioned(
            top: 16,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2533) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.green.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flag_rounded, color: AppColors.green, size: 13),
                  const SizedBox(width: 5),
                  Text(
                    'RDC',
                    style: TextStyle(
                      color: AppColors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Orbit dots
          _OrbitDots(color: palette.accent, isDark: isDark, radius: 115),
        ],
      ),
    );
  }
}

// ── Slides 2-5: Icône enrichie ───────────────────────────────────────────────

class _IconIllustration extends StatelessWidget {
  final _IllustType type;
  final MbongoThemePalette palette;
  final bool isDark;

  const _IconIllustration({required this.type, required this.palette, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  palette.accentStrong.withValues(alpha: isDark ? 0.15 : 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Mid decorative ring
          Container(
            width: 175,
            height: 175,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: palette.accent.withValues(alpha: isDark ? 0.10 : 0.07),
                width: 1,
              ),
            ),
          ),
          // Inner circle
          Container(
            width: 152,
            height: 152,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  palette.bannerGradient[0].withValues(alpha: isDark ? 0.92 : 1.0),
                  palette.bannerGradient.last.withValues(alpha: isDark ? 0.86 : 0.95),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: palette.accentStrong.withValues(alpha: isDark ? 0.38 : 0.22),
                  blurRadius: 36,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              _iconFor(type),
              color: Colors.white,
              size: 68,
            ),
          ),
          // Floating accent badge
          Positioned(
            top: 14,
            right: 20,
            child: _AccentBadge(type: type, palette: palette),
          ),
          // Secondary floating badge
          Positioned(
            bottom: 20,
            left: 16,
            child: _SecondaryBadge(type: type, palette: palette, isDark: isDark),
          ),
          // Orbit dots
          _OrbitDots(color: palette.accent, isDark: isDark, radius: 103),
        ],
      ),
    );
  }

  IconData _iconFor(_IllustType t) {
    switch (t) {
      case _IllustType.welcome:
        return Icons.account_balance_wallet_rounded;
      case _IllustType.account:
        return Icons.person_add_rounded;
      case _IllustType.transfer:
        return Icons.swap_horiz_rounded;
      case _IllustType.payments:
        return Icons.receipt_long_rounded;
      case _IllustType.security:
        return Icons.shield_rounded;
    }
  }
}

class _AccentBadge extends StatelessWidget {
  final _IllustType type;
  final MbongoThemePalette palette;
  const _AccentBadge({required this.type, required this.palette});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _badge(type);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.40),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 19),
    );
  }

  (IconData, Color) _badge(_IllustType t) {
    switch (t) {
      case _IllustType.welcome:
        return (Icons.star_rounded, AppColors.gold);
      case _IllustType.account:
        return (Icons.check_rounded, AppColors.green);
      case _IllustType.transfer:
        return (Icons.flash_on_rounded, AppColors.gold);
      case _IllustType.payments:
        return (Icons.qr_code_rounded, palette.accentStrong);
      case _IllustType.security:
        return (Icons.fingerprint_rounded, AppColors.green);
    }
  }
}

class _SecondaryBadge extends StatelessWidget {
  final _IllustType type;
  final MbongoThemePalette palette;
  final bool isDark;
  const _SecondaryBadge({required this.type, required this.palette, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final (label, value) = _content(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2333) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.accent.withValues(alpha: 0.20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: palette.accent,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  (String, String) _content(_IllustType t) {
    switch (t) {
      case _IllustType.welcome:
        return ('Solde', '0 CDF');
      case _IllustType.account:
        return ('Inscription', '5 min');
      case _IllustType.transfer:
        return ('Délai', 'Instant');
      case _IllustType.payments:
        return ('Services', '10+');
      case _IllustType.security:
        return ('Chiffrement', 'AES-256');
    }
  }
}

class _OrbitDots extends StatelessWidget {
  final Color color;
  final bool isDark;
  final double radius;
  const _OrbitDots({required this.color, required this.isDark, required this.radius});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: radius * 2 + 10,
      height: radius * 2 + 10,
      child: CustomPaint(
        painter: _OrbitPainter(
          color: color,
          opacity: isDark ? 0.28 : 0.18,
          radius: radius,
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  final Color color;
  final double opacity;
  final double radius;
  const _OrbitPainter({required this.color, required this.opacity, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;
    const dotAngles = [20.0, 80.0, 140.0, 200.0, 290.0, 345.0];
    const dotSizes = [5.0, 3.5, 5.5, 3.0, 4.5, 3.0];

    for (int i = 0; i < dotAngles.length; i++) {
      final angle = dotAngles[i] * math.pi / 180;
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);
      canvas.drawCircle(Offset(x, y), dotSizes[i], paint);
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => old.radius != radius;
}
