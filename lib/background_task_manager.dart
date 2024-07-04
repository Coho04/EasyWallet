import 'dart:async';
import 'package:easy_wallet/enum/payment_rate.dart';
import 'package:easy_wallet/enum/remember_cycle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class BackgroundTaskManager {
  static const String taskName = "io.github.coho04.easywallet.refresh";
  static const String lastNotificationKey = "LastNotificationScheduleDate";

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await _initNotifications();
    if (!kIsWeb) {
      Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
      Workmanager().registerPeriodicTask(
        "1",
        taskName,
        frequency: const Duration(minutes: 15), // For example, every 15 minutes
      );
    }
  }

  Future<TimeOfDay> _getUserNotificationTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? notificationTimeString = prefs.getString('notificationTime');
    if (notificationTimeString != null) {
      final timeParts = notificationTimeString.split(':');
      return TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
    }
    return TimeOfDay(hour: 9, minute: 0); // Default time
  }



  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> scheduleNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final String today = formatter.format(DateTime.now());
    final String? lastScheduledDate = prefs.getString(lastNotificationKey);

    if (lastScheduledDate == today) {
      if (kDebugMode) {
        print("Notifications were already scheduled today. Skipping.");
      }
      return;
    }

    final Database database = await _openDatabase();
    List<Map<String, dynamic>> subscriptions = await database.query(
      'subscriptions',
      where: 'isPaused = ? AND remembercycle != ?',
      whereArgs: [0, 'None'],
    );

    if (subscriptions.isEmpty) {
      return;
    }

    bool notificationsScheduled = false;
    for (var subscription in subscriptions) {
      DateTime? eventDate = _calculateNextBillDate(subscription);
      if (eventDate == null) continue;

      switch (subscription['remembercycle']) {
        case RememberCycle.dayBefore:
          eventDate = eventDate.subtract(const Duration(days: 1));
          break;
        case RememberCycle.twoDaysBefore:
          eventDate = eventDate.subtract(const Duration(days: 2));
          break;
        case RememberCycle.weekBefore:
          eventDate = eventDate.subtract(const Duration(days: 7));
          break;
        case RememberCycle.sameDay:
        default:
          break;
      }

      if (DateFormat('yyyy-MM-dd').format(eventDate) == today) {
        await _scheduleNotification(subscription);
        notificationsScheduled = true;
      }
    }

    if (notificationsScheduled) {
      prefs.setString(lastNotificationKey, today);
    }
  }

  Future<void> _scheduleNotification(Map<String, dynamic> subscription) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('your_channel_id', 'easy_wallet',
            channelDescription: "EasyWallet App Notify Channel",
            importance: Importance.max,
            priority: Priority.high,
            showWhen: false);
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Subscription Reminder',
      'Your subscription ${subscription['title']} is due soon!',
      platformChannelSpecifics,
      payload: 'item x',
    );
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

  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      final manager = BackgroundTaskManager();
      await manager.scheduleNotifications();
      return Future.value(true);
    });
  }
}
