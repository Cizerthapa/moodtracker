import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:math';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  Timer? _periodicTimer;

  Future<void> init() async {
    tz.initializeTimeZones();
    try {
      final dynamic tzData = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = tzData.toString();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      // Fallback to UTC if timezone plugin fails (common during hot reload/restart)
      tz.setLocalLocation(tz.getLocation('Etc/UTC'));
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {},
    );
  }

  Future<void> showInstantNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'instant_channel',
          'Instant Notifications',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    // ✅ v18 API: named parameters
    await _notificationsPlugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  Future<void> scheduleDailyNotifications() async {
    await _scheduleDaily(
      id: 100,
      title: 'Good Morning! ☀️',
      body:
          'Today is a beautiful day to track your progress. Have an amazing morning!',
      hour: 6,
      minute: 0,
    );

    await _scheduleDaily(
      id: 101,
      title: 'Sweet Dreams 🌙',
      body: 'You did great today. Rest well and see you tomorrow!',
      hour: 23,
      minute: 59,
    );
  }

  Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    // ✅ Fixed: use named parameters (v18+ API)
    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_channel',
          'Daily Messages',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  void startPeriodicNotifications() {
    _periodicTimer?.cancel();
    int count = 0;
    const maxCount = 30;

    final List<String> messages = [
      'Cizer loves you! ❤️',
      'What are you doing? Thinking of you!',
      'You are amazing! ✨',
      'Just a little reminder that you are special.',
      'How is your mood today? Hope it is great!',
      'Drink some water! 🥤',
      'Take a deep breath. 😌',
    ];

    _periodicTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (count >= maxCount) {
        timer.cancel();
        return;
      }
      final message = messages[Random().nextInt(messages.length)];
      await showInstantNotification('MoodTrack Alert', message);
      count++;
    });
  }

  void stopPeriodicNotifications() {
    _periodicTimer?.cancel();
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
