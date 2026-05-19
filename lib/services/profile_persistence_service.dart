import '../core/theme/mbongo_theme.dart';
import '../store/mbongo_store.dart';
import 'auth_service.dart';

class ProfilePersistenceService {
  static Future<void> loadProfileState() async {
    MbongoStore.profileType.value = await AuthService.getProfileType();
    MbongoStore.profilePhotoVerified.value =
        await AuthService.isProfilePhotoVerified();
    MbongoStore.phoneVerified.value = await AuthService.isPhoneVerified();
    MbongoStore.pinConfigured.value = await AuthService.isPinConfigured();
    MbongoStore.premiumEligible.value = await AuthService.isPremiumEligible();
    MbongoThemeController.setDarkMode(await AuthService.isDarkModeEnabled());
    MbongoThemeController.setTheme(await AuthService.getSelectedTheme());

    MbongoStore.refreshProfileType();
  }

  static Future<void> saveProfileType() async {
    await AuthService.setProfileType(MbongoStore.profileType.value);
  }

  static Future<void> savePhotoVerified(bool value) async {
    MbongoStore.profilePhotoVerified.value = value;
    MbongoStore.refreshProfileType();
    await AuthService.setProfilePhotoVerified(value);
    await AuthService.setProfileType(MbongoStore.profileType.value);
  }

  static Future<void> savePinConfigured(bool value) async {
    MbongoStore.pinConfigured.value = value;
    MbongoStore.refreshProfileType();
    await AuthService.setPinConfigured(value);
    await AuthService.setProfileType(MbongoStore.profileType.value);
  }

  static Future<void> savePhoneVerified(bool value) async {
    MbongoStore.phoneVerified.value = value;
    MbongoStore.refreshProfileType();
    await AuthService.setPhoneVerified(value);
    await AuthService.setProfileType(MbongoStore.profileType.value);
  }

  static Future<void> savePremiumEligible(bool value) async {
    MbongoStore.premiumEligible.value = value;
    MbongoStore.refreshProfileType();
    await AuthService.setPremiumEligible(value);
    await AuthService.setProfileType(MbongoStore.profileType.value);
  }
}
