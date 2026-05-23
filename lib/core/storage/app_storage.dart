import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final appStorageProvider = Provider<AppStorage>((ref) => AppStorage());

class AppStorage {
  static final AppStorage _instance = AppStorage._internal();
  factory AppStorage() => _instance;
  AppStorage._internal();

  static const _opts = AndroidOptions(encryptedSharedPreferences: true);
  static const _storage = FlutterSecureStorage(aOptions: _opts);

  static const _kAccess = 'mb_access_token';
  static const _kRefresh = 'mb_refresh_token';
  static const _kUser = 'mb_current_user';
  static const _kBioPhone = 'mb_bio_phone';
  static const _kBioPin = 'mb_bio_pin';

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> user,
  }) async {
    await Future.wait([
      _storage.write(key: _kAccess, value: accessToken),
      _storage.write(key: _kRefresh, value: refreshToken),
      _storage.write(key: _kUser, value: jsonEncode(user)),
    ]);
  }

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _kAccess, value: token);

  Future<String?> getAccessToken() => _storage.read(key: _kAccess);
  Future<String?> getRefreshToken() => _storage.read(key: _kRefresh);

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final raw = await _storage.read(key: _kUser);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return null;
  }

  Future<void> saveCurrentUser(Map<String, dynamic> user) =>
      _storage.write(key: _kUser, value: jsonEncode(user));

  Future<void> clearSession() => Future.wait([
        _storage.delete(key: _kAccess),
        _storage.delete(key: _kRefresh),
        _storage.delete(key: _kUser),
      ]);

  Future<bool> hasSession() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> saveBioCredentials(String phone, String pin) =>
      Future.wait([
        _storage.write(key: _kBioPhone, value: phone),
        _storage.write(key: _kBioPin, value: pin),
      ]).then((_) {});

  Future<({String? phone, String? pin})> getBioCredentials() async {
    final phone = await _storage.read(key: _kBioPhone);
    final pin = await _storage.read(key: _kBioPin);
    return (phone: phone, pin: pin);
  }

  Future<void> clearBioCredentials() => Future.wait([
        _storage.delete(key: _kBioPhone),
        _storage.delete(key: _kBioPin),
      ]).then((_) {});
}
