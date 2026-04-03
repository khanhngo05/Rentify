import 'package:shared_preferences/shared_preferences.dart';

class BiometricPreferenceService {
  static const String _keyPrefix = 'biometric_login_enabled_';
  static const String _globalEnabledKey = 'biometric_login_enabled_global';

  String _keyForUser(String uid) => '$_keyPrefix$uid';

  Future<bool> isEnabledForUser(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyForUser(uid)) ?? false;
  }

  Future<bool> isBiometricLoginEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_globalEnabledKey) ?? false;
  }

  Future<void> setEnabledForUser(String uid, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyForUser(uid), enabled);
    await prefs.setBool(_globalEnabledKey, enabled);
  }

  Future<void> clearForUser(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyForUser(uid));
  }
}
