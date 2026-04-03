import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RememberedUserProfile {
  const RememberedUserProfile({
    required this.uid,
    required this.displayName,
    this.avatarUrl,
    this.email,
  });

  final String uid;
  final String displayName;
  final String? avatarUrl;
  final String? email;
}

class BiometricPreferenceService {
  static const String _keyPrefix = 'biometric_login_enabled_';
  static const String _globalEnabledKey = 'biometric_login_enabled_global';
  static const String _lastUidKey = 'last_login_uid';
  static const String _lastDisplayNameKey = 'last_login_display_name';
  static const String _lastAvatarUrlKey = 'last_login_avatar_url';
  static const String _lastEmailKey = 'last_login_email';

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

  Future<void> saveRememberedUserProfile(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final displayName = user.displayName?.trim();
    final fallbackName = user.email?.trim();

    await prefs.setString(_lastUidKey, user.uid);
    await prefs.setString(
      _lastDisplayNameKey,
      (displayName?.isNotEmpty == true
          ? displayName!
          : (fallbackName ?? 'Rentify User')),
    );

    if (user.photoURL != null && user.photoURL!.trim().isNotEmpty) {
      await prefs.setString(_lastAvatarUrlKey, user.photoURL!.trim());
    } else {
      await prefs.remove(_lastAvatarUrlKey);
    }

    if (user.email != null && user.email!.trim().isNotEmpty) {
      await prefs.setString(_lastEmailKey, user.email!.trim());
    } else {
      await prefs.remove(_lastEmailKey);
    }
  }

  Future<RememberedUserProfile?> getRememberedUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_lastUidKey);
    final displayName = prefs.getString(_lastDisplayNameKey);

    if (uid == null ||
        uid.trim().isEmpty ||
        displayName == null ||
        displayName.trim().isEmpty) {
      return null;
    }

    final avatar = prefs.getString(_lastAvatarUrlKey);
    final email = prefs.getString(_lastEmailKey);
    return RememberedUserProfile(
      uid: uid,
      displayName: displayName,
      avatarUrl: avatar,
      email: email,
    );
  }

  Future<void> clearForUser(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyForUser(uid));
  }
}
