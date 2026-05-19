import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import 'mbongo_money_particles.dart';
import 'mbongo_sub_app_bar.dart';

class AppScaffold extends StatelessWidget {
  final String? title;
  final PreferredSizeWidget? appBar;
  final Widget child;
  final Widget? leading;
  final List<Widget>? actions;
  final bool safeArea;
  final EdgeInsetsGeometry? padding;
  final bool useGradient;
  final bool useParticles;
  final Color primaryParticleColor;
  final Color secondaryParticleColor;
  final double particleDensity;

  const AppScaffold({
    super.key,
    this.title,
    this.appBar,
    required this.child,
    this.leading,
    this.actions,
    this.safeArea = false,
    this.padding,
    this.useGradient = false,
    this.useParticles = false,
    this.primaryParticleColor = AppColors.primary,
    this.secondaryParticleColor = AppColors.gold,
    this.particleDensity = 0.75,
  });

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    final resolvedAppBar =
        appBar ??
        (title == null
            ? null
            : MbongoSubAppBar(
                title: title!,
                actions: actions,
              ));

    Widget body = child;

    if (padding != null) {
      body = Padding(
        padding: padding!,
        child: body,
      );
    }

    if (safeArea) {
      body = SafeArea(child: body);
    }

    if (useGradient || useParticles) {
      body = Stack(
        children: [
          if (useParticles)
            Positioned.fill(
              child: IgnorePointer(
                child: MbongoMoneyParticles(
                  color: primaryParticleColor,
                  count: (10 + (particleDensity * 10)).round().clamp(6, 36),
                  opacity: (0.05 + (particleDensity * 0.06)).clamp(0.05, 0.18),
                ),
              ),
            ),
          if (useGradient)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [palette.shellTop, palette.shellBottom],
                  ),
                ),
              ),
            ),
          Positioned.fill(child: body),
        ],
      );
    }

    return Scaffold(
      backgroundColor: palette.shellBottom,
      appBar: resolvedAppBar,
      body: body,
    );
  }
}

class MbongoPageScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool safeArea;
  final Color primaryParticleColor;
  final Color secondaryParticleColor;
  final double particleDensity;

  const MbongoPageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 18, 16, 28),
    this.safeArea = false,
    this.primaryParticleColor = AppColors.primary,
    this.secondaryParticleColor = AppColors.gold,
    this.particleDensity = 0.75,
  });

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: MbongoSubAppBar(title: title),
      useParticles: true,
      primaryParticleColor: primaryParticleColor,
      secondaryParticleColor: secondaryParticleColor,
      particleDensity: particleDensity,
      safeArea: safeArea,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
