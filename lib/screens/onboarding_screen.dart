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
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _illustAnim.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _goTo(int i) {
    HapticFeedback.selectionClick();
    _pageCtrl.animateToPage(
      i,
      duration: const Duration(milliseconds: 400),
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
        ? Colors.white.withValues(alpha: 0.70)
        : AppColors.lightSoft;
    final overlineColor = palette.accent;
    final skipColor = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : AppColors.lightMuted;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? palette.shellBottom : const Color(0xFFF4F7FF),
        body: SafeArea(
          child: Column(
            children: [
              // ── Top bar ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
                child: Row(
                  children: [
                    // Logo mark
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: palette.bannerGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text(
                          'M',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'MBONGO',
                      style: TextStyle(
                        color: palette.accent,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const Spacer(),
                    if (!isLast)
                      TextButton(
                        onPressed: _login,
                        style: TextButton.styleFrom(
                          foregroundColor: skipColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        child: const Text(
                          'J\'ai un compte',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Slides ───────────────────────────────────────────────
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

              // ── Dots ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (i) {
                    final active = i == _page;
                    return GestureDetector(
                      onTap: () => _goTo(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 3.5),
                        width: active ? 24 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: active
                              ? palette.accentStrong
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.20)
                                  : AppColors.lightMuted.withValues(alpha: 0.35)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // ── Buttons ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: palette.accentStrong,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          isLast ? 'Ouvrir mon compte' : 'Continuer',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _login,
                      child: Text(
                        'Déjà inscrit ? Se connecter',
                        style: TextStyle(
                          color: palette.accent,
                          fontSize: 14,
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
    final scale = CurvedAnimation(
      parent: illustAnim,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
    );
    final fade = CurvedAnimation(
      parent: illustAnim,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );
    final textFade = CurvedAnimation(
      parent: illustAnim,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          FadeTransition(
            opacity: fade,
            child: ScaleTransition(
              scale: scale,
              child: _Illustration(
                type: slide.type,
                palette: palette,
                isDark: isDark,
              ),
            ),
          ),
          const SizedBox(height: 44),

          // Text block
          FadeTransition(
            opacity: textFade,
            child: Column(
              children: [
                // Overline
                Text(
                  slide.overline.toUpperCase(),
                  style: TextStyle(
                    color: overlineColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 10),
                // Title
                Text(
                  slide.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    height: 1.18,
                    letterSpacing: -0.3,
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
                    height: 1.6,
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
    return SizedBox(
      width: 220,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  palette.accentStrong.withValues(alpha: isDark ? 0.18 : 0.10),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Inner circle
          Container(
            width: 148,
            height: 148,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  palette.bannerGradient[0].withValues(alpha: isDark ? 0.9 : 1.0),
                  palette.bannerGradient.last.withValues(alpha: isDark ? 0.85 : 0.95),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: palette.accentStrong.withValues(alpha: isDark ? 0.35 : 0.25),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              _iconFor(type),
              color: Colors.white,
              size: 64,
            ),
          ),
          // Floating accent badge
          Positioned(
            top: 12,
            right: 18,
            child: _AccentBadge(type: type, palette: palette),
          ),
          // Orbiting dots
          _OrbitDots(color: palette.accent, isDark: isDark),
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
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 18),
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

class _OrbitDots extends StatelessWidget {
  final Color color;
  final bool isDark;
  const _OrbitDots({required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: CustomPaint(
        painter: _OrbitPainter(
          color: color,
          opacity: isDark ? 0.30 : 0.20,
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  final Color color;
  final double opacity;
  const _OrbitPainter({required this.color, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;
    const r = 95.0;
    const dotAngles = [15.0, 75.0, 135.0, 195.0, 285.0];
    const dotSizes = [4.5, 3.0, 5.0, 3.5, 4.0];

    for (int i = 0; i < dotAngles.length; i++) {
      final angle = dotAngles[i] * math.pi / 180;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      canvas.drawCircle(Offset(x, y), dotSizes[i], paint);
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => false;
}
