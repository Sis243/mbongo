import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../features/auth/domain/app_user.dart';
import '../features/auth/presentation/auth_notifier.dart';
import '../services/auth_service.dart';
import '../widgets/common/mbongo_money_particles.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final AnimationController _glowController;

  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _rotationAnim;
  late final Animation<double> _textFadeAnim;
  late final Animation<Offset> _textSlideAnim;
  late final Animation<double> _logoLiftAnim;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _fadeAnim = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
    );

    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );

    _rotationAnim = Tween<double>(begin: -0.08, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _logoLiftAnim = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
      ),
    );

    _textFadeAnim = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.38, 0.78, curve: Curves.easeIn),
    );

    _textSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.38, 0.82, curve: Curves.easeOutCubic),
      ),
    );

    _glowAnim = Tween<double>(begin: 0.18, end: 0.34).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );

    _mainController.forward();
    _goNext();
  }

  Future<void> _goNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    // Timeout safety: FlutterSecureStorage can hang on some Android devices
    AppUser? authState;
    try {
      authState = await ref
          .read(authProvider.future)
          .timeout(const Duration(seconds: 6));
    } catch (_) {
      authState = null;
    }
    if (!mounted) return;

    if (authState != null) {
      context.go('/home');
    } else {
      final seen = await AuthService.hasSeenOnboarding();
      if (!mounted) return;
      context.go(seen ? '/auth/login' : '/onboarding');
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_mainController, _glowController]),
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF031C4A),
                  Color(0xFF0A5FB5),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -80,
                  left: -60,
                  child: _bgCircle(
                    size: 220,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                Positioned(
                  top: 120,
                  right: -70,
                  child: _bgCircle(
                    size: 180,
                    color: AppColors.gold.withValues(alpha: 0.08),
                  ),
                ),
                Positioned(
                  bottom: -90,
                  left: -40,
                  child: _bgCircle(
                    size: 220,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                Positioned(
                  bottom: 120,
                  right: 30,
                  child: _bgCircle(
                    size: 110,
                    color: AppColors.gold.withValues(alpha: 0.07),
                  ),
                ),
                const Positioned.fill(
                  child: IgnorePointer(
                    child: MbongoMoneyParticles(
                      color: AppColors.gold,
                      count: 19,
                      opacity: 0.10,
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.translate(
                        offset: Offset(0, _logoLiftAnim.value),
                        child: Opacity(
                          opacity: _fadeAnim.value,
                          child: Transform.rotate(
                            angle: _rotationAnim.value * math.pi,
                            child: Transform.scale(
                              scale: _scaleAnim.value,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 210,
                                    height: 210,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.gold.withValues(
                                            alpha: _glowAnim.value,
                                          ),
                                          blurRadius: 55,
                                          spreadRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 170,
                                    height: 170,
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(alpha: 0.07),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.14),
                                      ),
                                    ),
                                    child: Image.asset(
                                      'assets/images/mbongo_logo.png',
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) {
                                        return const Icon(
                                          Icons.account_balance_wallet,
                                          size: 90,
                                          color: AppColors.gold,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      FadeTransition(
                        opacity: _textFadeAnim,
                        child: SlideTransition(
                          position: _textSlideAnim,
                          child: const Column(
                            children: [
                              Text(
                                'MBONGO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Mobile Banking',
                                style: TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 18),
                              Text(
                                'powered by CADECO',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      FadeTransition(
                        opacity: _textFadeAnim,
                        child: const SizedBox(
                          width: 60,
                          child: LinearProgressIndicator(
                            color: AppColors.gold,
                            backgroundColor: Colors.white24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _bgCircle({
    required double size,
    required Color color,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
