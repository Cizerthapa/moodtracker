import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';

class FcmService {
  FcmService._internal();
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Requests permission and returns the FCM token.
  /// Returns null if permission denied or on web without VAPID key.
  Future<String?> initAndGetToken() async {
    log('FCM: Initializing and requesting token', name: 'Firebase');
    try {
      // Request permission (iOS / web)
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        log('FCM: Permission denied', name: 'Firebase');
        return null;
      }

      log('FCM: Getting token', name: 'Firebase');
      final token = await _messaging.getToken();
      log('FCM: Token retrieved: $token', name: 'Firebase');
      return token;
    } catch (e) {
      log('FCM: Error getting token: $e', name: 'Firebase');
      return null;
    }
  }

  /// Stream that fires when the FCM token is refreshed.
  Stream<String> get onTokenRefresh {
    log('FCM: Token refresh listener attached', name: 'Firebase');
    return _messaging.onTokenRefresh;
  }
}
