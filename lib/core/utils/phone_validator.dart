import 'package:flutter/services.dart';

/// Formate en temps réel : `0812345678` → `081 234 5678`
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final raw = digits.length > 10 ? digits.substring(0, 10) : digits;

    final buf = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i == 3 || i == 6) buf.write(' ');
      buf.write(raw[i]);
    }

    final formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class PhoneValidator {
  // Format local : 0 suivi de 9 chiffres (ex: 0812345678)
  // Opérateurs valides : 07X (Airtel), 08X (Vodacom/Orange), 09X (Africell)
  static final _local = RegExp(r'^0[7-9]\d{8}$');
  // Format international : +243 ou 243 suivi de 9 chiffres
  static final _intl = RegExp(r'^\+?243[7-9]\d{8}$');

  static bool isValid(String phone) {
    final cleaned = phone.trim().replaceAll(RegExp(r'[\s\-]'), '');
    return _local.hasMatch(cleaned) || _intl.hasMatch(cleaned);
  }

  static String? errorMessage(String phone) {
    if (phone.trim().isEmpty) return 'Entrez votre numéro de téléphone.';
    if (!isValid(phone)) {
      return 'Numéro invalide. Format attendu : 08XXXXXXXX ou +24308XXXXXXXX';
    }
    return null;
  }

  /// Normalise vers le format local 0XXXXXXXXX
  static String normalize(String phone) {
    final c = phone.trim().replaceAll(RegExp(r'[\s\-]'), '');
    if (c.startsWith('+243') && c.length == 13) return '0${c.substring(4)}';
    if (c.startsWith('243') && c.length == 12) return '0${c.substring(3)}';
    return c;
  }
}
