import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/launcher_icon');
    
    // Request permissions for Android 13+
    _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestExactAlarmsPermission();

    // iOS Initialization
    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(settings: initializationSettings);
  }

  Future<void> scheduleTaskNotifications(Task task) async {
    // Generate a unique base ID for the task using its start time hash
    int baseId = task.startDateTime.millisecondsSinceEpoch ~/ 100000;

    // Cancel existing notifications for this task to avoid duplicates if updated
    await cancelTaskNotifications(baseId);

    final now = DateTime.now();
    
    final settingsBox = Hive.box('settings');
    final bool notificationsEnabled = settingsBox.get('notificationsEnabled', defaultValue: true);
    
    if (!notificationsEnabled) return;

    final double delay = settingsBox.get('notificationDelay', defaultValue: 30.0).toDouble();

    final earlyReminder = task.startDateTime.subtract(Duration(minutes: delay.toInt()));

    if (earlyReminder.isAfter(now)) {
      await _scheduleNotification(
        id: baseId,
        title: 'Upcoming Task in ${delay.toInt()} mins',
        body: 'Your task "${task.title}" is starting soon.',
        scheduledDate: earlyReminder,
      );
    }
  }

  Future<void> cancelTaskNotifications(int baseId) async {
    await _notificationsPlugin.cancel(id: baseId);
  }

  Future<void> cancelTask(Task task) async {
    int baseId = task.startDateTime.millisecondsSinceEpoch ~/ 100000;
    await cancelTaskNotifications(baseId);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'taskify_channel_id',
      'Taskify Alerts',
      channelDescription: 'Notifications for upcoming tasks',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
