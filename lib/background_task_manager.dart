import 'dart:async';
import 'package:easy_wallet/enum/payment_rate.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';

class BackgroundTaskManager {
  static const String taskName = "io.github.coho04.easywallet.refresh";
  static const String lastNotificationKey = "LastNotificationScheduleDate";
  static const String groupKey = "com.easy_wallet.SUBSCRIPTION_NOTIFICATIONS";

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    print('Initializing background task manager.');
    await _initNotifications();
    if (!kIsWeb) {
      print('Initializing Workmanager.');
      Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
      Workmanager()
          .registerPeriodicTask(
        "io.github.coho04.easywallet.periodicTask.id.1.1",
        "io.github.coho04.easywallet.periodicTask.id.1",
        existingWorkPolicy: ExistingWorkPolicy.append,
        frequency: const Duration(minutes: 15),
      )
          .then((value) {
        print('Periodic task registered.');
        _showNotification("Background Task", "Periodic task registered.");
      });

      // Führe den ersten Check sofort aus
      await scheduleNotifications();
    }
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    tz.initializeTimeZones();
  }

  Future<TimeOfDay> _getUserNotificationTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? notificationTimeString = prefs.getString('notification_time');
    if (notificationTimeString != null) {
      final timeParts = notificationTimeString.split(':');
      return TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
    }
    return const TimeOfDay(hour: 9, minute: 0);
  }

  Future<void> scheduleNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final String today = formatter.format(DateTime.now());
    final String? lastScheduledDate = prefs.getString(lastNotificationKey);

    _showNotification("Subscription Check", "Subscription check executed");

    if (kDebugMode) {
      print("Last scheduled date: $lastScheduledDate");
    }
    if (lastScheduledDate == today) {
      if (kDebugMode) {
        print("Notifications were already scheduled today. Skipping.");
      }
      return;
    }

    final TimeOfDay userNotificationTime = await _getUserNotificationTime();
    final DateTime now = DateTime.now();
    final DateTime notificationDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      userNotificationTime.hour,
      userNotificationTime.minute,
    );

    if (now.isAfter(notificationDateTime)) {
      return;
    }

    final Database database = await _openDatabase();
    List<Map<String, dynamic>> subscriptions = await database.query(
      'subscriptions',
      where: 'isPaused = ? AND remembercycle != ?',
      whereArgs: [0, 'None'],
    );

    if (subscriptions.isEmpty) {
      if (kDebugMode) {
        print("No subscriptions found that require notifications.");
      }
      return;
    }

    bool notificationsScheduled = false;
    for (var subscription in subscriptions) {
      DateTime? eventDate = _calculateNextBillDate(subscription);
      if (eventDate == null) continue;

      switch (subscription['remembercycle']) {
        case 'day_before':
          eventDate = eventDate.subtract(const Duration(days: 1));
          break;
        case 'two_days_before':
          eventDate = eventDate.subtract(const Duration(days: 2));
          break;
        case 'week_before':
          eventDate = eventDate.subtract(const Duration(days: 7));
          break;
        case 'same_day':
        default:
          break;
      }

      if (DateFormat('yyyy-MM-dd').format(eventDate) == today) {
        await _scheduleNotification(subscription, notificationDateTime);
        notificationsScheduled = true;
        if (kDebugMode) {
          print(
              "Scheduled notification for subscription: ${subscription['title']}");
        }
      }
    }

    if (notificationsScheduled) {
      prefs.setString(lastNotificationKey, today);
      if (kDebugMode) {
        print("Notifications were scheduled for today.");
      }
      _showNotification(
          "Notifications Scheduled", "Notifications were scheduled for today.");
    } else {
      if (kDebugMode) {
        print("No notifications were scheduled for today.");
      }
      _showNotification(
          "No Notifications", "No notifications were scheduled for today.");
    }
  }

  Future<void> _scheduleNotification(
      Map<String, dynamic> subscription, DateTime scheduledTime) async {
    int notificationId =
        DateTime.now().millisecondsSinceEpoch.remainder(100000);

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'easy_wallet',
      'easy_wallet',
      channelDescription: "EasyWallet App Notify Channel",
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      groupKey: groupKey,
      setAsGroupSummary: false,
    );

    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      'Subscription Reminder',
      'Your subscription ${subscription['title']} is due soon!',
      tz.TZDateTime.from(scheduledTime, tz.local),
      platformChannelSpecifics,
      payload: 'item x',
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    if (kDebugMode) {
      print(
          "Notification scheduled: ${subscription['title']} at $scheduledTime");
    }
  }

  DateTime? _calculateNextBillDate(Map<String, dynamic> subscription) {
    if (subscription['date'] == null) return null;

    DateTime startBillDate = DateTime.parse(subscription['date']);
    DateTime today = DateTime.now();
    Duration interval;

    if (subscription['repeatPattern'] == PaymentRate.monthly.value) {
      interval = const Duration(days: 30);
    } else if (subscription['repeatPattern'] == PaymentRate.yearly.value) {
      interval = const Duration(days: 365);
    } else {
      return null;
    }

    while (startBillDate.isBefore(today)) {
      startBillDate = startBillDate.add(interval);
    }

    if (kDebugMode) {
      print(
          "Next bill date calculated for ${subscription['title']}: $startBillDate");
    }

    return startBillDate;
  }

  Future<Database> _openDatabase() async {
    return openDatabase(
      join(await getDatabasesPath(), 'easywallet.db'),
      onCreate: (db, version) {
        return db.execute(
          '''
          CREATE TABLE subscriptions(
            id INTEGER PRIMARY KEY, 
            title TEXT, 
            amount REAL, 
            isPaused INTEGER, 
            remembercycle TEXT,
            repeatPattern TEXT,
            date TEXT
          )
          ''',
        );
      },
      version: 1,
    );
  }

  Future<void> _showNotification(String title, String body) async {
    int notificationId =
        DateTime.now().millisecondsSinceEpoch.remainder(100000);

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'default_channel_id',
      'default_channel_name',
      channelDescription: 'default_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      groupKey: groupKey,
      setAsGroupSummary: false,
    );

    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      // print("Background task executed: $task");
      // final manager = BackgroundTaskManager();
      // await manager._initNotifications();
      // await manager._showNotification(
      //     "Background Task", "Background task executed: $task");
      // await manager.scheduleNotifications();
      // if (kDebugMode) {
      //   print("Background task executed: $task");
      // }
      // await manager._showNotification(
      //     "Background Task", "Background task executed: $task");
      return Future.value(true);
    });
  }
}
