import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../domain/app_user.dart';

// AuthProvider — source unique de vérité pour la session
final authProvider = AsyncNotifierProvider<AuthNotifier, AppUser?>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    return ref.read(authRepositoryProvider).restoreSession();
  }

  Future<void> login({required String phone, required String pin}) async {
    state = const AsyncLoading();
    try {
      final user = await ref.read(authRepositoryProvider).login(phone: phone, pin: pin);
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> register({
    required String name,
    required String phone,
    required String pin,
    String? email,
  }) async {
    state = const AsyncLoading();
    try {
      final user = await ref.read(authRepositoryProvider).register(
            name: name,
            phone: phone,
            pin: pin,
            email: email,
          );
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }

  Future<void> loginWithOtp({required String phone, required String code}) async {
    state = const AsyncLoading();
    try {
      final user = await ref.read(authRepositoryProvider).loginWithOtp(phone: phone, code: code);
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> changePin({required String currentPin, required String newPin}) async {
    await ref.read(authRepositoryProvider).changePin(
          currentPin: currentPin,
          newPin: newPin,
        );
  }

  Future<void> updateProfile({String? name, String? email}) async {
    final updated = await ref.read(authRepositoryProvider).updateProfile(name: name, email: email);
    state = AsyncData(updated);
  }

  bool get isAuthenticated => state.valueOrNull != null;

  AppUser? get currentUser => state.valueOrNull;
}
