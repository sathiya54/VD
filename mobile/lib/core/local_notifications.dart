import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Thin wrapper around flutter_local_notifications for on-device reminder
/// notifications (separate from any server-side push notifications).
///
/// NOTE: This wires up plugin initialization and simple immediate
/// notifications. Precise time-zone-aware scheduling (`zonedSchedule`)
/// additionally requires the `timezone` package and platform-specific
/// initialization; wire that in when a reminder needs to fire at an exact
/// future wall-clock time while the app is closed.
class LocalNotifications {
  LocalNotifications._internal();
  static final LocalNotifications instance = LocalNotifications._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<void> showReminderNow({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'reminders_channel',
      'Reminders',
      channelDescription: 'Virtual Diary reminders and alerts',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());
    await _plugin.show(id, title, body, details);
  }

  Future<void> cancel(int id) => _plugin.cancel(id);

  Future<void> cancelAll() => _plugin.cancelAll();
}
