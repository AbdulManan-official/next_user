import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../utils/app_urls.dart';
import 'api_client.dart';

/// FCM and Push Notification service handler using modern non-deprecated Firebase Messaging 17.0+ APIs.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  bool _initialized = false;
  String? _activeToken;

  String? get activeToken => _activeToken;

  /// Request permissions, listen to onRegistered, and register device.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (kDebugMode) {
        debugPrint(
          '[NotificationService] Notification permission status: ${settings.authorizationStatus}',
        );
      }

      // Listen for token registration and refresh events
      _fcm.onRegistered.listen((newToken) {
        _activeToken = newToken;
        if (kDebugMode) {
          debugPrint('[NotificationService] FCM token registered/refreshed: $newToken');
        }
        syncTokenToBackend(newToken);
      });

      // Register device with Firebase Cloud Messaging
      await _fcm.register();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationService] Error initializing push notifications: $e');
      }
    }
  }

  /// Fetch active FCM device push token
  Future<String?> getDeviceToken() async {
    if (_activeToken != null && _activeToken!.isNotEmpty) {
      return _activeToken;
    }
    try {
      final tokenFuture = _fcm.onRegistered.first.timeout(
        const Duration(seconds: 4),
        onTimeout: () => '',
      );
      await _fcm.register();
      final token = await tokenFuture;
      if (token.isNotEmpty) {
        _activeToken = token;
        return token;
      }
      return _activeToken;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationService] Failed to retrieve FCM token: $e');
      }
      return _activeToken;
    }
  }

  /// Sends device FCM push token to the backend server (POST /user/fcm-token)
  Future<void> syncTokenToBackend(String token) async {
    try {
      await ApiClient.instance.post(
        AppUrls.fcmToken,
        data: {'fcm_token': token},
      );
      if (kDebugMode) {
        debugPrint('[NotificationService] FCM token successfully synced to backend');
      }
    } catch (e) {
      // Non-fatal if backend endpoint is still being deployed
      if (kDebugMode) {
        debugPrint('[NotificationService] Failed to sync FCM token to backend: $e');
      }
    }
  }

  /// Revokes device push token on logout
  Future<void> deleteToken() async {
    try {
      await _fcm.unregister();
      _activeToken = null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationService] Error unregistering FCM token: $e');
      }
    }
  }
}
