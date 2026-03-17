import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:moodtrack/core/constants/app_strings.dart';
import 'package:moodtrack/core/constants/app_constants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  static const MethodChannel _channel = MethodChannel(AppConstants.notificationMethodChannel);
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

    // Request permissions for Android 13+ and exact alarms
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  Future<void> showInstantNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          AppConstants.instantChannelId,
          AppConstants.instantChannelName,
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
      title: AppStrings.morningTitle,
      body: AppStrings.morningBody,
      hour: 6,
      minute: 0,
    );

    await _scheduleDaily(
      id: 101,
      title: AppStrings.nightTitle,
      body: AppStrings.nightBody,
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
          AppConstants.dailyChannelId,
          AppConstants.dailyChannelName,
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

  Future<void> startPeriodicNotifications() async {
    // Attempt to start the native Android background service
    try {
      await _channel.invokeMethod('startBackground');
    } on PlatformException catch (e) {
      print("Failed to start background service: '${e.message}'.");
      
      // Fallback for iOS or if native fails
      _periodicTimer?.cancel();
      int count = 0;
      const maxCount = 30;

      final List<String> messages = AppStrings.periodicMessages;

      _periodicTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
        if (count >= maxCount) {
          timer.cancel();
          return;
        }
        final message = messages[Random().nextInt(messages.length)];
        await showInstantNotification(AppStrings.periodicHeader, message);
        count++;
      });
    }
  }

  Future<void> stopPeriodicNotifications() async {
    try {
      await _channel.invokeMethod('stopBackground');
    } catch (e) {
      print("Failed to stop background service: $e");
    }
    _periodicTimer?.cancel();
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
