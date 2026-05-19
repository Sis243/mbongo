import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/mbongo_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MbongoApp()));
}

class MbongoApp extends ConsumerWidget {
  const MbongoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return ValueListenableBuilder<String>(
      valueListenable: MbongoThemeController.selectedThemeId,
      builder: (context, _, __) {
        return ValueListenableBuilder<bool>(
          valueListenable: MbongoThemeController.darkModeEnabled,
          builder: (context, darkMode, __) {
            return MaterialApp.router(
              title: 'MBONGO',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(darkMode: darkMode),
              routerConfig: router,
            );
          },
        );
      },
    );
  }
}
