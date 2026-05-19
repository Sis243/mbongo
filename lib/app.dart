import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/mbongo_theme.dart';
import 'screens/main_shell.dart';

class MbongoApp extends StatelessWidget {
  const MbongoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: ValueListenableBuilder<String>(
        valueListenable: MbongoThemeController.selectedThemeId,
        builder: (context, _, __) {
          return ValueListenableBuilder<bool>(
            valueListenable: MbongoThemeController.darkModeEnabled,
            builder: (context, darkModeEnabled, __) {
              return MaterialApp(
                title: 'MBONGO',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light(darkMode: darkModeEnabled),
                home: const MainShell(),
              );
            },
          );
        },
      ),
    );
  }
}
