import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Thin wrapper around flutter_local_notifications so the rest of the app
/// doesn't depend on plugin details. Failures are swallowed: local push is a
/// nice-to-have on top of the in-app notifications screen, not a hard
/// requirement, so a platform without notification permissions should never
/// crash the app.
class LocalNotificationService {
  LocalNotificationService._internal();
  static final LocalNotificationService instance = LocalNotificationService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    try {
      await _plugin.initialize(settings);
      _initialized = true;
    } catch (_) {
      // Notifications are best-effort; ignore platforms without support.
    }
  }

  Future<void> show({required String title, required String body}) async {
    if (!_initialized) await init();
    const androidDetails = AndroidNotificationDetails(
      'mentor_link_channel',
      'MentorLink Notifications',
      channelDescription: 'Booking and chat updates',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());
    try {
      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
      );
    } catch (_) {
      // Ignore — e.g. desktop/test environments without notification support.
    }
  }
}
