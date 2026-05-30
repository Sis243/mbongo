import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/mbongo_theme.dart';
import 'firebase_options.dart';
import 'providers/pending_tab_provider.dart';

final _localNotifications = FlutterLocalNotificationsPlugin();

// tick-tick: wait 0ms, vibrate 150ms, pause 100ms, vibrate 150ms
final _vibrationPattern = Int64List.fromList([0, 150, 100, 150]);

// v2 forces channel re-creation with the bundled sound on existing installs
final _androidChannel = AndroidNotificationChannel(
  'mbongo_channel_v2',
  'MBONGO',
  description: 'Notifications de transactions et alertes MBONGO.',
  importance: Importance.high,
  sound: const RawResourceAndroidNotificationSound('mbongo_notif'),
  enableVibration: true,
  vibrationPattern: Int64List.fromList([0, 150, 100, 150]),
);

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void _routeFromData(Map<String, dynamic>? data) {
  if (data == null) return;
  final type = data['type'] as String? ?? '';
  NotificationNavigation.navigateToTab(tabIndexForNotificationType(type));
}

Future<void> _initLocalNotifications() async {
  await _localNotifications.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      ),
    ),
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      final type = response.payload ?? '';
      NotificationNavigation.navigateToTab(tabIndexForNotificationType(type));
    },
  );
  await _localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_androidChannel);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await _initLocalNotifications();

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _routeFromData(message.data);
  });

  final initial = await FirebaseMessaging.instance.getInitialMessage();
  if (initial != null) {
    Future.delayed(const Duration(milliseconds: 600), () {
      _routeFromData(initial.data);
    });
  }

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    final type = message.data['type'] as String? ?? '';
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
          sound: const RawResourceAndroidNotificationSound('mbongo_notif'),
          enableVibration: true,
          vibrationPattern: _vibrationPattern,
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          sound: 'mbongo_notif.wav',
          presentSound: true,
          presentAlert: true,
          presentBadge: true,
        ),
      ),
      payload: type,
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
