// lib/core/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_settings_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidInitializationSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: androidInitializationSettings,
    );

    await _notificationsPlugin.initialize(initializationSettings);
    tz.initializeTimeZones();
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final bool areNotificationsEnabled = await NotificationSettingsService.getNotificationsEnabled();
    if (!areNotificationsEnabled) {
      print("Notifications are disabled by the user.");
      return; // Dừng lại, không gửi thông báo
    }

    if (scheduledTime.isBefore(DateTime.now())) {
      return;
    }

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_channel_id',
          'Task Reminders',
          channelDescription: 'Channel for task reminder notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      // THAY ĐỔI 1: Thêm tham số bắt buộc 'androidScheduleMode'
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

      // THAY ĐỔI 2: Tham số cũ 'uiLocalNotificationDateInterpretation'
      // đã được thay thế bằng 'matchDateTimeComponents'
      // Dùng để so khớp cho thông báo lặp lại, không cần thiết cho thông báo 1 lần.
      // matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}