import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'mbongo_theme.dart';

class AppTheme {
  static const String _premiumFont = 'SF Pro Display';
  static const List<String> _premiumFallback = [
    'Inter',
    'Segoe UI',
    'Roboto',
    'Helvetica Neue',
    'Arial',
  ];

  static TextStyle _textStyle({
    required Color color,
    required double size,
    required FontWeight weight,
    double height = 1.18,
  }) {
    return TextStyle(
      fontFamily: _premiumFont,
      fontFamilyFallback: _premiumFallback,
      color: color,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: 0,
      height: height,
    );
  }

  static ThemeData light({bool darkMode = true}) {
    final palette = MbongoThemeController.current;
    final textColor = darkMode ? AppColors.text : AppColors.lightText;
    final softTextColor = darkMode ? AppColors.textSoft : AppColors.lightSoft;
    final mutedColor = darkMode ? AppColors.muted : AppColors.lightMuted;
    final fieldFill = darkMode
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.92);
    final fieldBorder = darkMode
        ? Colors.white.withValues(alpha: 0.10)
        : AppColors.border.withValues(alpha: 0.20);
    final base = ThemeData(
      useMaterial3: true,
      brightness: darkMode ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: palette.shellBottom,
      fontFamily: _premiumFont,
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.accentStrong,
        brightness: darkMode ? Brightness.dark : Brightness.light,
        primary: palette.accentStrong,
        secondary: AppColors.gold,
        surface: palette.panel,
        error: AppColors.red,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: palette.shellBottom,
      cardColor: palette.panel,
      dividerColor: AppColors.border,
      splashColor: Colors.white.withValues(alpha: 0.05),
      highlightColor: Colors.white.withValues(alpha: 0.03),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: _textStyle(
          color: textColor,
          size: 21,
          weight: FontWeight.w800,
          height: 1.1,
        ),
      ),

      textTheme: TextTheme(
        displayLarge: _textStyle(
          color: textColor,
          size: 32,
          weight: FontWeight.w800,
          height: 1.04,
        ),
        displayMedium: _textStyle(
          color: textColor,
          size: 26,
          weight: FontWeight.w800,
          height: 1.06,
        ),
        headlineSmall: _textStyle(
          color: textColor,
          size: 22,
          weight: FontWeight.w800,
          height: 1.08,
        ),
        titleLarge: _textStyle(
          color: textColor,
          size: 18,
          weight: FontWeight.w800,
          height: 1.12,
        ),
        titleMedium: _textStyle(
          color: textColor,
          size: 16,
          weight: FontWeight.w700,
          height: 1.14,
        ),
        bodyLarge: _textStyle(
          color: textColor,
          size: 15,
          weight: FontWeight.w600,
          height: 1.28,
        ),
        bodyMedium: _textStyle(
          color: softTextColor,
          size: 13,
          weight: FontWeight.w600,
          height: 1.32,
        ),
        labelLarge: _textStyle(
          color: textColor,
          size: 14,
          weight: FontWeight.w800,
          height: 1.12,
        ),
        labelMedium: _textStyle(
          color: softTextColor,
          size: 12,
          weight: FontWeight.w700,
          height: 1.12,
        ),
        labelSmall: _textStyle(
          color: mutedColor,
          size: 10.5,
          weight: FontWeight.w700,
          height: 1.1,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        hintStyle: _textStyle(
          color: mutedColor,
          size: 13,
          weight: FontWeight.w600,
          height: 1.2,
        ),
        labelStyle: _textStyle(
          color: softTextColor,
          size: 13,
          weight: FontWeight.w600,
          height: 1.2,
        ),
        prefixIconColor: palette.accentStrong,
        suffixIconColor: mutedColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: fieldBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: fieldBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: palette.accent.withValues(alpha: 0.95),
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.red, width: 1.4),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.accentStrong,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: _textStyle(
            color: Colors.white,
            size: 15,
            weight: FontWeight.w800,
            height: 1.08,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          minimumSize: const Size(double.infinity, 56),
          side: BorderSide(
            color: fieldBorder,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: _textStyle(
            color: textColor,
            size: 15,
            weight: FontWeight.w800,
            height: 1.08,
          ),
        ),
      ),
    );
  }
}
