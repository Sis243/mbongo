import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/app_scaffold.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const List<String> _languages = [
    'Francais',
    'English',
    'Swahili',
    'Tshiluba',
    'Kikongo',
    'Lingala',
  ];

  bool _loading = true;
  bool notifications = true;
  bool darkMode = true;
  bool transactionSounds = true;
  String selectedLanguage = 'Francais';
  String selectedTheme = 'cadeco';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    notifications = await AuthService.isNotificationsEnabled();
    darkMode = await AuthService.isDarkModeEnabled();
    transactionSounds = await AuthService.isTransactionSoundsEnabled();
    selectedLanguage = await AuthService.getSelectedLanguage();
    selectedTheme = await AuthService.getSelectedTheme();
    MbongoThemeController.setTheme(selectedTheme);

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _setNotifications(bool value) async {
    setState(() => notifications = value);
    await AuthService.setNotificationsEnabled(value);
  }

  Future<void> _setDarkMode(bool value) async {
    setState(() => darkMode = value);
    MbongoThemeController.setDarkMode(value);
    await AuthService.setDarkModeEnabled(value);
  }

  Future<void> _setTransactionSounds(bool value) async {
    setState(() => transactionSounds = value);
    await AuthService.setTransactionSounds(value);
  }

  Future<void> _setLanguage(String value) async {
    setState(() => selectedLanguage = value);
    await AuthService.setSelectedLanguage(value);
  }

  Future<void> _setTheme(String value) async {
    setState(() => selectedTheme = value);
    MbongoThemeController.setTheme(value);
    await AuthService.setSelectedTheme(value);
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    return MbongoPageScaffold(
      title: 'Themes',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _header(),
                const SizedBox(height: 18),
                _band(
                  title: 'Themes',
                  child: Column(
                    children: MbongoThemeController.palettes.map((palette) {
                      final selected = palette.id == selectedTheme;
                      return GestureDetector(
                        onTap: () => _setTheme(palette.id),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: selected
                                ? palette.accent.withValues(alpha: 0.10)
                                : palette.panelAlt,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: selected ? palette.accent : Colors.transparent,
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: palette.bannerGradient),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      palette.name,
                                      style: const TextStyle(
                                        color: AppColors.darkText,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      palette.description,
                                      style: const TextStyle(
                                        color: AppColors.darkMuted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (selected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: palette.accent,
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),
                _band(
                  title: 'Canaux',
                  child: Column(
                    children: [
                      _switchTile(
                        title: 'Notifications',
                        subtitle: 'Alertes de mouvements et changements sensibles',
                        value: notifications,
                        onChanged: _setNotifications,
                      ),
                      const SizedBox(height: 10),
                      _switchTile(
                        title: 'Sons de transaction',
                        subtitle: 'Retour sonore apres validation',
                        value: transactionSounds,
                        onChanged: _setTransactionSounds,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _band(
                  title: 'Interface',
                  child: Column(
                    children: [
                      _switchTile(
                        title: 'Mode sombre',
                        subtitle: 'Conserver l interface visuelle sombre',
                        value: darkMode,
                        onChanged: _setDarkMode,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: palette.panelAlt,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.24),
                          ),
                        ),
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedLanguage,
                          dropdownColor: palette.panelAlt,
                          style: const TextStyle(
                            color: AppColors.darkText,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Langue',
                            labelStyle: const TextStyle(
                              color: AppColors.darkMuted,
                            ),
                            prefixIcon: Icon(
                              Icons.language_rounded,
                              color: palette.accent,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Francais', child: Text('Francais')),
                            DropdownMenuItem(value: 'English', child: Text('English')),
                            DropdownMenuItem(value: 'Swahili', child: Text('Swahili')),
                            DropdownMenuItem(value: 'Tshiluba', child: Text('Tshiluba')),
                            DropdownMenuItem(value: 'Kikongo', child: Text('Kikongo')),
                            DropdownMenuItem(value: 'Lingala', child: Text('Lingala')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              _setLanguage(value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: palette.panelAlt,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.24),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Apercu linguistique',
                              style: TextStyle(
                                color: AppColors.darkText,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _languagePreview(selectedLanguage),
                              style: const TextStyle(
                                color: AppColors.darkMuted,
                                fontSize: 12.8,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _languages.map((language) {
                                final selected = language == selectedLanguage;
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? palette.accent.withValues(alpha: 0.12)
                                        : palette.panel,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    language,
                                    style: TextStyle(
                                      color: selected
                                          ? palette.accent
                                          : AppColors.darkMuted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                );
                              }).toList(),
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

  Widget _header() {
    final palette = MbongoThemeController.current;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette.bannerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preferences',
            style: TextStyle(
              color: palette.accentStrong,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Themes et interface',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choisissez votre rendu MBONGO et vos alertes.',
            style: TextStyle(
              color: const Color(0xFFE8EEF8),
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _band({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final palette = MbongoThemeController.current;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.darkMuted,
                    fontSize: 12.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  String _languagePreview(String language) {
    switch (language) {
      case 'English':
        return 'Welcome back. Payments, cards and transfers stay available in English where possible.';
      case 'Swahili':
        return 'Karibu tena. Malipo, kadi na uhamisho vinaanza kupatikana kwa Kiswahili.';
      case 'Tshiluba':
        return 'Twapandula. Bifuta, makadi ne kutumina mali bidi bipatshibue pa Tshiluba mu bipeta bimwe.';
      case 'Kikongo':
        return 'Tuvutukidi mbote. Mambu ya futa, bakadi mpe transfere me banda na Kikongo na bisika bisusu.';
      case 'Lingala':
        return 'Boyei malamu lisusu. Bofuti, bakarte mpe botindeli ezali kobanda na Lingala na bisika mosusu.';
      default:
        return 'Le francais reste complet. Les autres langues sont ajoutees progressivement selon les ecrans.';
    }
  }
}
