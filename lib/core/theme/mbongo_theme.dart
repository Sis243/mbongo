import 'package:flutter/material.dart';

class MbongoThemePalette {
  final String id;
  final String name;
  final String shortLabel;
  final String description;
  final Color shellTop;
  final Color shellBottom;
  final Color panel;
  final Color panelAlt;
  final Color accent;
  final Color accentStrong;
  final Color glow;
  final List<Color> bannerGradient;
  final List<Color> cardGradient;

  const MbongoThemePalette({
    required this.id,
    required this.name,
    required this.shortLabel,
    required this.description,
    required this.shellTop,
    required this.shellBottom,
    required this.panel,
    required this.panelAlt,
    required this.accent,
    required this.accentStrong,
    required this.glow,
    required this.bannerGradient,
    required this.cardGradient,
  });
}

class MbongoThemeController {
  static final ValueNotifier<String> selectedThemeId =
      ValueNotifier<String>('cadeco');
  static final ValueNotifier<bool> darkModeEnabled = ValueNotifier<bool>(true);

  static const List<MbongoThemePalette> palettes = [
    MbongoThemePalette(
      id: 'cadeco',
      name: 'Cadeco Bleu',
      shortLabel: 'Bleu',
      description: 'Bleu institutionnel, propre et rassurant.',
      shellTop: Color(0xFF081D44),
      shellBottom: Color(0xFF03152F),
      panel: Color(0xFF0A1F43),
      panelAlt: Color(0xFF102040),
      accent: Color(0xFF1FB7FF),
      accentStrong: Color(0xFF1E63D6),
      glow: Color(0x6627B0FF),
      bannerGradient: [Color(0xFF1B4EAA), Color(0xFF0D2D65), Color(0xFF18A7F4)],
      cardGradient: [Color(0xFF143E86), Color(0xFF0B2146)],
    ),
    MbongoThemePalette(
      id: 'fintech',
      name: 'Fintech Night',
      shortLabel: 'Night',
      description: 'Plus premium, contraste fort, touche fintech.',
      shellTop: Color(0xFF071B2D),
      shellBottom: Color(0xFF020C16),
      panel: Color(0xFF0A2232),
      panelAlt: Color(0xFF0C2A3E),
      accent: Color(0xFF2CE6C9),
      accentStrong: Color(0xFF1DA7E0),
      glow: Color(0x6638FFD8),
      bannerGradient: [Color(0xFF103C66), Color(0xFF081A2D), Color(0xFF1CCCB3)],
      cardGradient: [Color(0xFF0E3154), Color(0xFF071726)],
    ),
    MbongoThemePalette(
      id: 'royal',
      name: 'Royal Gold',
      shortLabel: 'Gold',
      description: 'Bleu profond avec accent or, style prestige.',
      shellTop: Color(0xFF101A39),
      shellBottom: Color(0xFF050B20),
      panel: Color(0xFF12224A),
      panelAlt: Color(0xFF141E45),
      accent: Color(0xFFF0B90B),
      accentStrong: Color(0xFF3478F6),
      glow: Color(0x66F0B90B),
      bannerGradient: [Color(0xFF1B3474), Color(0xFF0C1632), Color(0xFFF0B90B)],
      cardGradient: [Color(0xFF19346E), Color(0xFF0E1B3E)],
    ),
  ];

  static const List<MbongoThemePalette> lightPalettes = [
    MbongoThemePalette(
      id: 'cadeco',
      name: 'Cadeco Bleu',
      shortLabel: 'Jour',
      description: 'Version claire du bleu institutionnel MBONGO.',
      shellTop: Color(0xFFF5F9FF),
      shellBottom: Color(0xFFEAF2FF),
      panel: Color(0xFFFFFFFF),
      panelAlt: Color(0xFFFFFFFF),
      accent: Color(0xFF1E63D6),
      accentStrong: Color(0xFF0F4EA8),
      glow: Color(0x331E63D6),
      bannerGradient: [Color(0xFF1B4EAA), Color(0xFF2D7CC1), Color(0xFF1FB7FF)],
      cardGradient: [Color(0xFF1B4EAA), Color(0xFF0F4EA8)],
    ),
    MbongoThemePalette(
      id: 'fintech',
      name: 'Fintech Light',
      shortLabel: 'Aqua',
      description: 'Version claire fintech avec accents cyan.',
      shellTop: Color(0xFFF2FFFD),
      shellBottom: Color(0xFFE8F7FF),
      panel: Color(0xFFFFFFFF),
      panelAlt: Color(0xFFFFFFFF),
      accent: Color(0xFF00A88F),
      accentStrong: Color(0xFF0878B8),
      glow: Color(0x332CE6C9),
      bannerGradient: [Color(0xFF0878B8), Color(0xFF00A88F), Color(0xFF2CE6C9)],
      cardGradient: [Color(0xFF0878B8), Color(0xFF075E91)],
    ),
    MbongoThemePalette(
      id: 'royal',
      name: 'Royal Light',
      shortLabel: 'Or',
      description: 'Version claire prestige avec accent or.',
      shellTop: Color(0xFFFFFBF2),
      shellBottom: Color(0xFFF1F5FF),
      panel: Color(0xFFFFFFFF),
      panelAlt: Color(0xFFFFFFFF),
      accent: Color(0xFFD99A00),
      accentStrong: Color(0xFF1B4EAA),
      glow: Color(0x33F0B90B),
      bannerGradient: [Color(0xFF1B3474), Color(0xFF3478F6), Color(0xFFF0B90B)],
      cardGradient: [Color(0xFF1B3474), Color(0xFF132A63)],
    ),
  ];

  static MbongoThemePalette get current =>
      paletteById(selectedThemeId.value, darkMode: darkModeEnabled.value);

  static MbongoThemePalette paletteById(String id, {bool? darkMode}) {
    final source = (darkMode ?? darkModeEnabled.value) ? palettes : lightPalettes;
    return source.firstWhere(
      (palette) => palette.id == id,
      orElse: () => source.first,
    );
  }

  static void setTheme(String id) {
    selectedThemeId.value = id;
  }

  static void setDarkMode(bool value) {
    darkModeEnabled.value = value;
  }
}
