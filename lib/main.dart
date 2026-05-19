import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/mbongo_theme.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
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
