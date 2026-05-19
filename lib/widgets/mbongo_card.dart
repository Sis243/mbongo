import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/mbongo_theme.dart';

class MbongoCard extends StatelessWidget {
  final Widget child;

  const MbongoCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}
