import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_client.dart';
import '../../../core/storage/app_storage.dart';
import '../domain/app_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    client: ref.read(dioClientProvider),
    storage: ref.read(appStorageProvider),
  );
});

class AuthRepository {
  final DioClient _client;
  final AppStorage _storage;

  const AuthRepository({required DioClient client, required AppStorage storage})
      : _client = client,
        _storage = storage;

  Future<String?> _getFcmToken() async {
    try {
      return await FirebaseMessaging.instance.getToken()
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      return null;
    }
  }

  Future<AppUser> login({
    required String phone,
    required String pin,
  }) async {
    final fcmToken = await _getFcmToken();
    final data = await _client.post(
      '/auth/login',
      {'phone': phone, 'pin': pin, if (fcmToken != null) 'fcmToken': fcmToken},
      auth: false,
    );

    final tokens = (data['tokens'] as Map?)?.cast<String, dynamic>() ?? {};
    final accessToken = (tokens['accessToken'] ?? data['accessToken']) as String? ?? '';
    final refreshToken = (tokens['refreshToken'] ?? data['refreshToken']) as String? ?? '';
    final userMap = Map<String, dynamic>.from(
      (data['user'] as Map?)?.cast<String, dynamic>() ?? data,
    );

    final user = AppUser.fromMap(userMap);
    // Sauvegarde session — try-catch pour ne jamais bloquer le login si storage indisponible
    try {
      await _storage.saveSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: user.toMap(),
      ).timeout(const Duration(seconds: 8));
    } catch (_) {
      // Storage peut échouer sur certains appareils — on laisse l'utilisateur entrer quand même
    }

    return user;
  }

  Future<AppUser> register({
    required String name,
    required String phone,
    required String pin,
    String? email,
  }) async {
    final fcmToken = await _getFcmToken();
    final data = await _client.post(
      '/auth/register',
      {
        'name': name,
        'phone': phone,
        'pin': pin,
        if (email != null && email.isNotEmpty) 'email': email,
        if (fcmToken != null) 'fcmToken': fcmToken,
      },
      auth: false,
    );

    final tokens = (data['tokens'] as Map?)?.cast<String, dynamic>() ?? {};
    final accessToken = (tokens['accessToken'] ?? data['accessToken']) as String? ?? '';
    final refreshToken = (tokens['refreshToken'] ?? data['refreshToken']) as String? ?? '';
    final userMap = Map<String, dynamic>.from(
      (data['user'] as Map?)?.cast<String, dynamic>() ?? data,
    );

    final user = AppUser.fromMap(userMap);
    try {
      await _storage.saveSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: user.toMap(),
      ).timeout(const Duration(seconds: 8));
    } catch (_) {}

    return user;
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _client.post(
          '/auth/logout',
          {'refreshToken': refreshToken},
        );
      }
    } catch (_) {
      // Always clear locally even if server call fails
    }
    await _storage.clearSession();
  }

  Future<AppUser> loginWithOtp({required String phone, required String code}) async {
    final fcmToken = await _getFcmToken();
    final data = await _client.post(
      '/auth/login-otp',
      {'phone': phone, 'code': code, if (fcmToken != null) 'fcmToken': fcmToken},
      auth: false,
    );

    final tokens = (data['tokens'] as Map?)?.cast<String, dynamic>() ?? {};
    final accessToken = (tokens['accessToken'] ?? data['accessToken']) as String? ?? '';
    final refreshToken = (tokens['refreshToken'] ?? data['refreshToken']) as String? ?? '';
    final userMap = Map<String, dynamic>.from(
      (data['user'] as Map?)?.cast<String, dynamic>() ?? data,
    );

    final user = AppUser.fromMap(userMap);
    try {
      await _storage.saveSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: user.toMap(),
      ).timeout(const Duration(seconds: 8));
    } catch (_) {}

    return user;
  }

  Future<void> changePin({required String currentPin, required String newPin}) async {
    await _client.post('/auth/change-pin', {
      'currentPin': currentPin,
      'newPin': newPin,
    });
  }

  Future<AppUser> updateProfile({String? name, String? email}) async {
    final body = <String, dynamic>{};
    if (name != null && name.trim().isNotEmpty) body['name'] = name.trim();
    if (email != null && email.trim().isNotEmpty) body['email'] = email.trim();
    final fresh = await _client.patch('/users/me', body);
    final updated = AppUser.fromMap(fresh);
    await _storage.saveCurrentUser(updated.toMap());
    return updated;
  }

  Future<AppUser?> restoreSession() async {
    final hasSession = await _storage.hasSession();
    if (!hasSession) return null;

    final userMap = await _storage.getCurrentUser();
    if (userMap == null) return null;

    try {
      // Refresh profile from server
      final fresh = await _client.get('/users/me');
      final updated = AppUser.fromMap(fresh);
      await _storage.saveCurrentUser(updated.toMap());
      return updated;
    } catch (_) {
      // Fallback to cached user if network unavailable
      return AppUser.fromMap(userMap);
    }
  }
}
