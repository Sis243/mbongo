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

  Future<AppUser> login({
    required String phone,
    required String pin,
  }) async {
    final data = await _client.post(
      '/auth/login',
      {'phone': phone, 'pin': pin},
      auth: false,
    );

    final accessToken = data['accessToken'] as String? ?? '';
    final refreshToken = data['refreshToken'] as String? ?? '';
    final userMap = Map<String, dynamic>.from(
      (data['user'] as Map?)?.cast<String, dynamic>() ?? data,
    );

    final user = AppUser.fromMap(userMap);
    await _storage.saveSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user.toMap(),
    );

    return user;
  }

  Future<AppUser> register({
    required String name,
    required String phone,
    required String pin,
  }) async {
    final data = await _client.post(
      '/auth/register',
      {'name': name, 'phone': phone, 'pin': pin},
      auth: false,
    );

    final accessToken = data['accessToken'] as String? ?? '';
    final refreshToken = data['refreshToken'] as String? ?? '';
    final userMap = Map<String, dynamic>.from(
      (data['user'] as Map?)?.cast<String, dynamic>() ?? data,
    );

    final user = AppUser.fromMap(userMap);
    await _storage.saveSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user.toMap(),
    );

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
