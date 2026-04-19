import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FcmService {
  FcmService._internal();
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Requests permission and returns the FCM token.
  /// Returns null if permission denied or on web without VAPID key.
  Future<String?> initAndGetToken() async {
    try {
      // Request permission (iOS / web)
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[FCM] Permission denied.');
        return null;
      }

      final token = await _messaging.getToken();
      debugPrint('[FCM] Token: $token');
      return token;
    } catch (e) {
      debugPrint('[FCM] Error getting token: $e');
      return null;
    }
  }

  /// Stream that fires when the FCM token is refreshed.
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;
}
