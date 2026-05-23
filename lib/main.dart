import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/mbongo_theme.dart';
import 'firebase_options.dart';

final _localNotifications = FlutterLocalNotificationsPlugin();

const _androidChannel = AndroidNotificationChannel(
  'mbongo_channel',
  'MBONGO',
  description: 'Notifications de transactions et alertes MBONGO.',
  importance: Importance.high,
);

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> _initLocalNotifications() async {
  await _localNotifications.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );
  await _localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_androidChannel);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await _initLocalNotifications();

  // Affichage des notifications FCM quand l'app est en premier plan
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    _localNotifications.show(
      notification.hashCode,
      notification.title ?? 'MBONGO',
      notification.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  });

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
