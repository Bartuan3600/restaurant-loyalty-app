import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Local notifications (demo). Production: Firebase Cloud Messaging / APNs via the backend.
class Notify {
  static final _p = FlutterLocalNotificationsPlugin(); static bool _ready = false; static int _id = 0;
  static Future<void> init() async {
    try {
      await _p.initialize(settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false)));
      _ready = true;
    } catch (_) {}
  }
  static Future<void> requestPermission() async {
    if (!_ready) return;
    await _p.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    await _p.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, badge: true, sound: true);
  }
  static Future<void> show(String title, String body) async {
    if (!_ready) return;
    await _p.show(id: _id++, title: title, body: body, notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails('deals', 'Deals & Punkte', importance: Importance.high, priority: Priority.high), iOS: DarwinNotificationDetails()));
  }
}
