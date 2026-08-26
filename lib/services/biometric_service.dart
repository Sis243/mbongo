import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> canCheck() async {
    try {
      // canCheckBiometrics = hardware present AND at least one biometric enrolled
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      if (canCheckBiometrics) return true;
      // Fallback: device supports authentication AND has biometrics available
      final isDeviceSupported = await _auth.isDeviceSupported();
      if (!isDeviceSupported) return false;
      final available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> supportsFaceRecognition() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.face);
  }

  static Future<bool> supportsFingerprint() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.fingerprint) ||
        biometrics.contains(BiometricType.strong) ||
        biometrics.contains(BiometricType.weak);
  }

  static Future<String> securityLabel() async {
    final hasFace = await supportsFaceRecognition();
    final hasFingerprint = await supportsFingerprint();

    if (hasFace && hasFingerprint) return 'Empreinte digitale et visage';
    if (hasFace) return 'Reconnaissance faciale';
    if (hasFingerprint) return 'Empreinte digitale';
    return 'Biometrie';
  }

  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Authentifiez-vous pour accéder à Mbongo',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
