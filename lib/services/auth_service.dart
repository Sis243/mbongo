import 'package:shared_preferences/shared_preferences.dart';

import '../core/storage/app_storage.dart';

class AuthService {
  // Token operations delegate to AppStorage (flutter_secure_storage)
  static final _secure = AppStorage();

  static const String _loggedInKey = 'mbongo_logged_in';
  static const String _biometricEnabledKey = 'mbongo_biometric_enabled';

  static const String _profileImagePathKey = 'mbongo_profile_image_path';
  static const String _profileTypeKey = 'mbongo_profile_type';
  static const String _profilePhotoVerifiedKey = 'mbongo_profile_photo_verified';

  static const String _notificationsEnabledKey = 'mbongo_notifications_enabled';
  static const String _darkModeEnabledKey = 'mbongo_dark_mode_enabled';
  static const String _transactionSoundsKey = 'mbongo_transaction_sounds';
  static const String _selectedLanguageKey = 'mbongo_selected_language';
  static const String _selectedThemeKey = 'mbongo_selected_theme';
  static const String _seenOnboardingKey = 'mbongo_seen_onboarding';
  static const String _faceRecognitionEnabledKey = 'mbongo_face_recognition_enabled';
  static const String _livenessCheckEnabledKey = 'mbongo_liveness_check_enabled';
  static const String _palmRecognitionEnabledKey = 'mbongo_palm_recognition_enabled';
  static const String _nfcPaymentsEnabledKey = 'mbongo_nfc_payments_enabled';

  static const String _phoneVerifiedKey = 'mbongo_phone_verified';
  static const String _pinConfiguredKey = 'mbongo_pin_configured';
  static const String _premiumEligibleKey = 'mbongo_premium_eligible';
  static const String _kycSubmittedKey = 'mbongo_kyc_submitted';
  static const String _kycSelfiePathKey = 'mbongo_kyc_selfie_path';
  static const String _kycDocumentTypeKey = 'mbongo_kyc_document_type';
  static const String _kycDocumentNumberKey = 'mbongo_kyc_document_number';
  static const String _kycSheetNameKey = 'mbongo_kyc_sheet_name';
  static const String _kycStatusKey = 'mbongo_kyc_status';
  static const String _kycDocumentFrontPathKey = 'mbongo_kyc_document_front_path';
  static const String _kycDocumentBackPathKey = 'mbongo_kyc_document_back_path';
  static const String _kycRefusalReasonKey = 'mbongo_kyc_refusal_reason';
  static const String _kycSubmittedAtKey = 'mbongo_kyc_submitted_at';
  static const String _registerDraftNameKey = 'mbongo_register_draft_name';
  static const String _registerDraftPhoneKey = 'mbongo_register_draft_phone';

  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seenOnboardingKey) ?? false;
  }

  static Future<void> setSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenOnboardingKey, true);
  }

  static Future<void> setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, value);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loggedInKey) ?? false;
  }

  static Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> user,
  }) async {
    await _secure.saveSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, true);
  }

  static Future<String?> getAccessToken() => _secure.getAccessToken();

  static Future<String?> getRefreshToken() => _secure.getRefreshToken();

  static Future<Map<String, dynamic>?> getCurrentUser() =>
      _secure.getCurrentUser();

  static Future<void> setCurrentUser(Map<String, dynamic> user) =>
      _secure.saveCurrentUser(user);

  static Future<void> logout() async {
    await _secure.clearSession();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, false);
  }

  static Future<void> setBiometricEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, value);
  }

  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  static Future<void> setProfileImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileImagePathKey, path);
  }

  static Future<String?> getProfileImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profileImagePathKey);
  }

  static Future<void> setProfileType(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileTypeKey, value);
  }

  static Future<String> getProfileType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profileTypeKey) ?? 'Standard';
  }

  static Future<void> setProfilePhotoVerified(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_profilePhotoVerifiedKey, value);
  }

  static Future<bool> isProfilePhotoVerified() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_profilePhotoVerifiedKey) ?? false;
  }

  static Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, value);
  }

  static Future<bool> isNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  static Future<void> setDarkModeEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeEnabledKey, value);
  }

  static Future<bool> isDarkModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeEnabledKey) ?? true;
  }

  static Future<void> setTransactionSounds(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_transactionSoundsKey, value);
  }

  static Future<bool> isTransactionSoundsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_transactionSoundsKey) ?? true;
  }

  static Future<void> setSelectedLanguage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedLanguageKey, value);
  }

  static Future<String> getSelectedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedLanguageKey) ?? 'Francais';
  }

  static Future<void> setSelectedTheme(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedThemeKey, value);
  }

  static Future<String> getSelectedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedThemeKey) ?? 'cadeco';
  }

  static Future<void> setFaceRecognitionEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_faceRecognitionEnabledKey, value);
  }

  static Future<bool> isFaceRecognitionEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_faceRecognitionEnabledKey) ?? false;
  }

  static Future<void> setLivenessCheckEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_livenessCheckEnabledKey, value);
  }

  static Future<bool> isLivenessCheckEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_livenessCheckEnabledKey) ?? true;
  }

  static Future<void> setPalmRecognitionEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_palmRecognitionEnabledKey, value);
  }

  static Future<bool> isPalmRecognitionEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_palmRecognitionEnabledKey) ?? false;
  }

  static Future<void> setNfcPaymentsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_nfcPaymentsEnabledKey, value);
  }

  static Future<bool> isNfcPaymentsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_nfcPaymentsEnabledKey) ?? true;
  }

  static Future<void> setPhoneVerified(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_phoneVerifiedKey, value);
  }

  static Future<bool> isPhoneVerified() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_phoneVerifiedKey) ?? true;
  }

  static Future<void> setPinConfigured(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pinConfiguredKey, value);
  }

  static Future<bool> isPinConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pinConfiguredKey) ?? true;
  }

  static Future<void> setPremiumEligible(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumEligibleKey, value);
  }

  static Future<bool> isPremiumEligible() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_premiumEligibleKey) ?? true;
  }

  static Future<void> setKycSubmitted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kycSubmittedKey, value);
  }

  static Future<bool> isKycSubmitted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kycSubmittedKey) ?? false;
  }

  static Future<void> setKycSelfiePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kycSelfiePathKey, path);
  }

  static Future<String?> getKycSelfiePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kycSelfiePathKey);
  }

  static Future<void> setKycDocumentType(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kycDocumentTypeKey, value);
  }

  static Future<String> getKycDocumentType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kycDocumentTypeKey) ?? 'Carte nationale';
  }

  static Future<void> setKycDocumentNumber(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kycDocumentNumberKey, value);
  }

  static Future<String> getKycDocumentNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kycDocumentNumberKey) ?? '';
  }

  static Future<void> setKycSheetName(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kycSheetNameKey, value);
  }

  static Future<String> getKycSheetName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kycSheetNameKey) ?? '';
  }

  static Future<void> setKycStatus(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kycStatusKey, value);
  }

  static Future<String> getKycStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kycStatusKey) ?? 'non_commence';
  }

  static Future<void> setKycDocumentFrontPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kycDocumentFrontPathKey, path);
  }

  static Future<String?> getKycDocumentFrontPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kycDocumentFrontPathKey);
  }

  static Future<void> setKycDocumentBackPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kycDocumentBackPathKey, path);
  }

  static Future<String?> getKycDocumentBackPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kycDocumentBackPathKey);
  }

  static Future<void> setKycRefusalReason(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kycRefusalReasonKey, value);
  }

  static Future<String> getKycRefusalReason() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kycRefusalReasonKey) ?? '';
  }

  static Future<void> setKycSubmittedAt(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kycSubmittedAtKey, value);
  }

  static Future<String> getKycSubmittedAt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kycSubmittedAtKey) ?? '';
  }

  static Future<void> setRegisterDraftName(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_registerDraftNameKey, value);
  }

  static Future<String> getRegisterDraftName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_registerDraftNameKey) ?? '';
  }

  static Future<void> setRegisterDraftPhone(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_registerDraftPhoneKey, value);
  }

  static Future<String> getRegisterDraftPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_registerDraftPhoneKey) ?? '';
  }

  static Future<void> clearRegisterDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_registerDraftNameKey);
    await prefs.remove(_registerDraftPhoneKey);
  }

  static Future<void> clearProfileCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileImagePathKey);
    await prefs.remove(_profileTypeKey);
    await prefs.remove(_profilePhotoVerifiedKey);
    await prefs.remove(_kycSubmittedKey);
    await prefs.remove(_kycSelfiePathKey);
    await prefs.remove(_kycDocumentTypeKey);
    await prefs.remove(_kycDocumentNumberKey);
    await prefs.remove(_kycSheetNameKey);
    await prefs.remove(_kycStatusKey);
    await prefs.remove(_kycDocumentFrontPathKey);
    await prefs.remove(_kycDocumentBackPathKey);
    await prefs.remove(_kycRefusalReasonKey);
    await prefs.remove(_kycSubmittedAtKey);
    await prefs.remove(_registerDraftNameKey);
    await prefs.remove(_registerDraftPhoneKey);
    await prefs.remove(_faceRecognitionEnabledKey);
    await prefs.remove(_livenessCheckEnabledKey);
    await prefs.remove(_palmRecognitionEnabledKey);
    await prefs.remove(_nfcPaymentsEnabledKey);
  }
}
