import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../features/auth/presentation/auth_notifier.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';
import '../../services/inactivity_lock_service.dart';

class InactivityLockWrapper extends StatefulWidget {
  final Widget child;
  const InactivityLockWrapper({super.key, required this.child});

  @override
  State<InactivityLockWrapper> createState() => _InactivityLockWrapperState();
}

class _InactivityLockWrapperState extends State<InactivityLockWrapper> {
  @override
  void initState() {
    super.initState();
    inactivityLock.start();
    inactivityLock.addListener(_onLockChanged);
  }

  @override
  void dispose() {
    inactivityLock.removeListener(_onLockChanged);
    super.dispose();
  }

  void _onLockChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => inactivityLock.recordActivity(),
      onPointerMove: (_) => inactivityLock.recordActivity(),
      child: Stack(
        children: [
          widget.child,
          if (inactivityLock.isLocked)
            const _LockScreen(),
        ],
      ),
    );
  }
}

class _LockScreen extends ConsumerStatefulWidget {
  const _LockScreen();

  @override
  ConsumerState<_LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<_LockScreen> {
  final _pinCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final available = await BiometricService.canCheck();
    final enabled = await AuthService.isBiometricEnabled();
    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled;
    });
    if (available && enabled) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) _unlockWithBiometric();
    }
  }

  Future<void> _forceLogout() async {
    await AuthService.logout();
    if (!mounted) return;
    inactivityLock.unlock();
    if (context.mounted) context.go('/auth/login');
  }

  Future<void> _unlockWithPin() async {
    final pin = _pinCtrl.text.trim();
    if (pin.isEmpty) return;
    setState(() { _loading = true; _error = null; });

    try {
      final creds = await _getStoredPhone();
      if (creds == null) {
        await _forceLogout();
        return;
      }
      await ref.read(authProvider.notifier).login(phone: creds, pin: pin);
      if (!mounted) return;
      inactivityLock.unlock();
    } catch (e) {
      if (!mounted) return;
      // Compte introuvable ou session invalide → logout forcé
      final msg = e.toString().toLowerCase();
      if (msg.contains('401') || msg.contains('403') || msg.contains('404')
          || msg.contains('not found') || msg.contains('unauthorized')) {
        await _forceLogout();
        return;
      }
      setState(() { _loading = false; _error = 'Code PIN incorrect.'; });
    }
  }

  Future<void> _unlockWithBiometric() async {
    final ok = await BiometricService.authenticate();
    if (!ok || !mounted) return;
    inactivityLock.unlock();
  }

  Future<String?> _getStoredPhone() async {
    final user = await AuthService.getCurrentUser();
    return user?['phone']?.toString();
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.shellTop, palette.shellBottom],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: palette.panel,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.lock_rounded, color: AppColors.gold, size: 34),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Application verrouillée',
                  style: TextStyle(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Entrez votre code PIN pour continuer',
                  style: TextStyle(color: AppColors.textSoft, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: palette.panel,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _pinCtrl,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        autofocus: !(_biometricAvailable && _biometricEnabled),
                        onSubmitted: (_) => _unlockWithPin(),
                        decoration: InputDecoration(
                          labelText: 'Code PIN',
                          prefixIcon: const Icon(Icons.pin_rounded),
                          errorText: _error,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _unlockWithPin,
                          child: _loading
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2.4))
                              : const Text('Déverrouiller'),
                        ),
                      ),
                      if (_biometricAvailable && _biometricEnabled) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _unlockWithBiometric,
                            icon: const Icon(Icons.fingerprint_rounded),
                            label: const Text('Empreinte / Face ID'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: _loading ? null : _forceLogout,
                        icon: const Icon(Icons.logout_rounded, size: 16, color: AppColors.muted),
                        label: const Text(
                          'Changer de compte',
                          style: TextStyle(color: AppColors.muted, fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
