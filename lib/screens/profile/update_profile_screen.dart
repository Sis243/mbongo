import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../features/auth/presentation/auth_notifier.dart';
import '../../widgets/common/mbongo_sub_app_bar.dart';
import '../../widgets/common/mbongo_money_particles.dart';

class UpdateProfileScreen extends ConsumerStatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  ConsumerState<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends ConsumerState<UpdateProfileScreen> {
  late final TextEditingController _nameCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final current = ref.read(authProvider).valueOrNull;
    _nameCtrl = TextEditingController(text: current?.name ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _toast('Veuillez saisir votre nom.');
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(authProvider.notifier).updateProfile(name: name);
      if (!mounted) return;
      _toast('Profil mis a jour.');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _toast(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    final current = ref.watch(authProvider).valueOrNull;

    return Scaffold(
      backgroundColor: palette.shellBottom,
      appBar: MbongoSubAppBar(title: 'Modifier le profil'),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [palette.shellTop, palette.shellBottom],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: MbongoMoneyParticles(
                color: palette.accent,
                count: 12,
                opacity: 0.07,
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: palette.bannerGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person_rounded, color: palette.accentStrong),
                          const SizedBox(width: 8),
                          const Text(
                            'Informations personnelles',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Modifiez votre nom d affichage. Le numero de telephone ne peut pas etre change depuis l application.',
                        style: TextStyle(
                          color: Color(0xFFE8EEF8),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: palette.panelAlt,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (current?.phone != null) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: palette.panel,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border.withValues(alpha: 0.22)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.phone_rounded, color: palette.accent, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Telephone',
                                      style: TextStyle(
                                        color: AppColors.darkMuted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      current!.phone,
                                      style: const TextStyle(
                                        color: AppColors.darkText,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.border.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'Non modifiable',
                                  style: TextStyle(
                                    color: AppColors.darkMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextField(
                        controller: _nameCtrl,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: palette.panel,
                          labelText: 'Nom complet',
                          labelStyle: const TextStyle(color: AppColors.muted),
                          prefixIcon: Icon(Icons.person_outline_rounded, color: palette.accent),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.24)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: palette.accent, width: 1.4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.accentStrong,
                    ),
                    child: Text(_saving ? 'Enregistrement...' : 'Enregistrer les modifications'),
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
