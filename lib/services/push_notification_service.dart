import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'firebase_service.dart';

/// Entry-point cho xử lý push khi app ở background/terminated.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Push background: ${message.messageId}');
}

/// Quản lý đăng ký FCM token theo user để nhận thông báo đẩy.
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseService _firebaseService = FirebaseService();

  StreamSubscription<User?>? _authStateSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  String? _lastKnownToken;
  bool _initialized = false;

  bool get _isMessagingSupportedPlatform {
    if (kIsWeb) {
      return true;
    }

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (!_isMessagingSupportedPlatform) {
      debugPrint('Push skipped: unsupported platform');
      return;
    }

    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );

      FirebaseMessaging.onMessage.listen((message) {
        debugPrint('Push foreground: ${message.notification?.title}');
      });

      _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((newToken) {
        _lastKnownToken = newToken;
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          _firebaseService.saveUserFcmToken(uid, newToken);
        }
      });

      _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen(
        _syncTokenForUser,
      );

      await _syncTokenForUser(FirebaseAuth.instance.currentUser);
    } catch (e) {
      debugPrint('Push init skipped due to error: $e');
      _initialized = false;
      return;
    }
  }

  Future<void> _syncTokenForUser(User? user) async {
    if (!_isMessagingSupportedPlatform) {
      return;
    }

    String? token;
    try {
      token = await _messaging.getToken();
    } catch (e) {
      debugPrint('Get FCM token failed: $e');
      return;
    }

    if (token == null || token.trim().isEmpty) return;

    _lastKnownToken = token;

    if (user == null) return;
    await _firebaseService.saveUserFcmToken(user.uid, token);
  }

  Future<void> dispose() async {
    await _authStateSubscription?.cancel();
    await _tokenRefreshSubscription?.cancel();

    if (!_isMessagingSupportedPlatform) {
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final token = _lastKnownToken;
    if (uid != null && token != null && token.trim().isNotEmpty) {
      await _firebaseService.removeUserFcmToken(uid, token);
    }
  }
}
