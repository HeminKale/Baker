import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

/// Top-level (not a class member) because FirebaseMessaging.onBackgroundMessage
/// requires a top-level or static function -- runs in its own isolate.
/// Registered from main.dart once Firebase.initializeApp() is wired up
/// (blocked on `flutterfire configure`, see Milestone 6 plan §6.5).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No-op for now -- background messages with a `notification` payload are
  // shown by the OS automatically. Only foreground messages need the local
  // notifications plugin (see FcmService._showLocalNotification below).
}

/// Registers this device for push + shows foreground pushes locally (Android
/// doesn't auto-show FCM notification-type messages while the app is in the
/// foreground). No-ops entirely if Firebase hasn't been initialized yet, so
/// it's safe to call before main.dart's Firebase wiring lands.
class FcmService {
  FcmService(this._dio);

  final Dio _dio;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _localNotificationsInitialized = false;

  Future<void> registerAndListen() async {
    if (Firebase.apps.isEmpty) return;

    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await messaging.getToken();
      if (token != null) {
        await _sendTokenToBackend(token);
      }
      messaging.onTokenRefresh.listen(_sendTokenToBackend);
      FirebaseMessaging.onMessage.listen(_showLocalNotification);
    } catch (err, stack) {
      debugPrint('FcmService.registerAndListen failed: $err\n$stack');
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      await _dio.post<void>('/v1/users/fcm-token', data: {'fcmToken': token});
    } catch (err) {
      // Best-effort -- next app open or token refresh retries.
      debugPrint('Failed to sync FCM token: $err');
    }
  }

  Future<void> _ensureLocalNotificationsInitialized() async {
    if (_localNotificationsInitialized) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    _localNotificationsInitialized = true;
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _ensureLocalNotificationsInitialized();
    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel',
          'Baker Ally notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService(ref.watch(dioProvider));
});
