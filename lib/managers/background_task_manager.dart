import 'dart:async';
import 'package:easy_wallet/enum/payment_rate.dart';
import 'package:easy_wallet/enum/remember_cycle.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

import '../generated/l10n.dart';

class BackgroundTaskManager {
  static const String groupKey = "com.easy_wallet.SUBSCRIPTION_NOTIFICATIONS";

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await _initNotifications();
    await scheduleNotifications();
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android)) {
      // Register periodic task only on Android
      Workmanager().initialize(callbackDispatcher, isInDebugMode: kDebugMode);
      Workmanager().registerPeriodicTask(
        "1",
        "easy_wallet",
        existingWorkPolicy: ExistingWorkPolicy.append,
        frequency: const Duration(minutes: 15),
      );
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
    final String? notificationTimeString = prefs.getString('notificationTime');
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
      final Database database = await _openDatabase();
      List<Map<String, dynamic>> subscriptions = await database.query(
        'subscriptions',
        where: 'isPaused = ? AND remembercycle != ?',
        whereArgs: [0, 'None'],
      );

      if (subscriptions.isEmpty) {
        return;
      }

      for (var subscription in subscriptions) {
        DateTime? eventDate = _calculateNextBillDate(subscription);
        if (eventDate == null) continue;

        RememberCycle cycle = RememberCycle.findByName(subscription['remembercycle']);
        switch (cycle) {
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
          final String notificationKey =
              'notification_${subscription['id']}_$today';
          final bool alreadyNotified = prefs.getBool(notificationKey) ?? false;

          if (!alreadyNotified) {
            final String title = S.current.subscriptionReminder;
            final String body = S.current.subscriptionIsDueSoon(subscription['title']);
            await _showNotification(subscription, title, body);
            prefs.setBool(notificationKey, true);
          }
        }
      }
    }
  }

  Future<void> _showNotification(Map<String, dynamic> subscription, String title, String body) async {
    int notificationId =
    DateTime.now().millisecondsSinceEpoch.remainder(100000);

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'easy_wallet_channel_id', // Kanal-ID
      'EasyWallet', // Kanalname
      channelDescription: "EasyWallet App Notify Channel",
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      groupKey: groupKey,
      setAsGroupSummary: false,
      icon: '@mipmap/ic_launcher', // Icon
    );

    const DarwinNotificationDetails iosPlatformChannelSpecifics =
    DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    try {
      await flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        platformChannelSpecifics,
        payload: 'item x',
      );
    } catch (e) {
      if (kDebugMode) {
        print("Error showing notification: $e");
      }
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
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final manager = BackgroundTaskManager();
    await manager._initNotifications();
    await manager.scheduleNotifications();
    return Future.value(true);
  });
}
