import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recurring_task.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static const String doneActionId = 'done_action';
  static const String notDoneActionId = 'not_done_action';

  Future<void> initialize() async {
    tz.initializeTimeZones();
    final TimezoneInfo timeZoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _notificationTapBackground,
    );
  }

  void _onNotificationResponse(NotificationResponse response) {
    _notificationTapBackground(response);
  }

  Future<void> requestPermissions() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
  }

  Future<void> scheduleTaskNotifications(RecurringTask task) async {
    await cancelTaskNotifications(task.id);

    final String baseId = task.id.replaceAll(RegExp(r'[^0-9]'), '');
    final int numericBaseId = baseId.isEmpty ? task.hashCode : int.tryParse(baseId.substring(0, baseId.length > 8 ? 8 : baseId.length)) ?? task.hashCode;


    for (int dayOfWeek in task.selectedDays) {
      int notificationId = numericBaseId + dayOfWeek;

      final tz.TZDateTime scheduledDate = _nextInstanceOfDayAndTime(dayOfWeek, task.time);

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'recurring_tasks_channel',
        'Recurring Tasks',
        channelDescription: 'Notifications for recurring tasks',
        importance: Importance.max,
        priority: Priority.high,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            doneActionId,
            'Mark Done',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            notDoneActionId,
            'Not Done',
            showsUserInterface: true,
          ),
        ],
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await _notificationsPlugin.zonedSchedule(
        id: notificationId,
        title: 'Task Reminder',
        body: task.title,
        scheduledDate: scheduledDate,
        notificationDetails: platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: task.id,
      );
    }
  }

  Future<void> cancelTaskNotifications(String taskId) async {
    // Because we generate multiple IDs based on the day,
    // it's tricky to cancel just by task ID if we don't know the days.
    // The safest way is to cancel all and reschedule, or compute the IDs again.
    // Assuming task IDs are somewhat consistent, we can just cancel the ones we created.
    // For a robust solution, we should probably keep track of scheduled notification IDs.

    // As a simple workaround, we can fetch all pending and cancel those matching our task logic
    final List<PendingNotificationRequest> pendingNotifications =
        await _notificationsPlugin.pendingNotificationRequests();

    for (var notification in pendingNotifications) {
      if (notification.payload == taskId) {
        await _notificationsPlugin.cancel(id: notification.id);
      }
    }
  }

  tz.TZDateTime _nextInstanceOfDayAndTime(int dayOfWeek, TimeOfDay time) {
    tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If scheduled for today but time has passed, or it's another day
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // 1 = Monday, 7 = Sunday in Dart.
    // Find the next day that matches dayOfWeek
    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }
}

@pragma('vm:entry-point')
void _notificationTapBackground(NotificationResponse notificationResponse) async {
  if (notificationResponse.actionId != null && notificationResponse.payload != null) {
    final String taskId = notificationResponse.payload!;
    final String status = notificationResponse.actionId == NotificationService.doneActionId ? 'done' : 'not_done';

    final prefs = await SharedPreferences.getInstance();
    final recordsJson = prefs.getStringList('blockit_task_records') ?? [];
    List<TaskRecord> records = recordsJson.map((r) => TaskRecord.fromJson(r)).toList();

    final now = DateTime.now();
    final normalizedDate = DateTime(now.year, now.month, now.day);

    records.removeWhere((r) =>
      r.taskId == taskId &&
      r.date.year == normalizedDate.year &&
      r.date.month == normalizedDate.month &&
      r.date.day == normalizedDate.day
    );

    records.add(TaskRecord(taskId: taskId, date: normalizedDate, status: status));

    final updatedRecordsJson = records.map((r) => r.toJson()).toList();
    await prefs.setStringList('blockit_task_records', updatedRecordsJson);
  }
}