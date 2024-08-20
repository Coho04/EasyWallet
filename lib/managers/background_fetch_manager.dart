import 'dart:async';
import 'package:easy_wallet/enum/payment_rate.dart';
import 'package:easy_wallet/enum/remember_cycle.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:background_fetch/background_fetch.dart';

import '../generated/l10n.dart';
import '../persistence_controller.dart';

class BackgroundFetchManager {
  static const String groupKey = "com.easy_wallet.SUBSCRIPTION_NOTIFICATIONS";

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await _initNotifications();
    await _configureBackgroundFetch();
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      defaultPresentAlert: true,
      defaultPresentBanner: true,
      defaultPresentSound: true,
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

  Future<void> _configureBackgroundFetch() async {
    BackgroundFetch.configure(
      BackgroundFetchConfig(
        minimumFetchInterval: 15,
        stopOnTerminate: false,
        enableHeadless: true,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresStorageNotLow: false,
        requiresDeviceIdle: false,
        requiredNetworkType: NetworkType.NONE,
      ),
      _onBackgroundFetch,
      _onBackgroundFetchTimeout,
    ).then((int status) {
    }).catchError((e) {
      Sentry.captureException(e);
    });

    BackgroundFetch.start().then((int status) {
    }).catchError((e) {
      Sentry.captureException(e);
    });
  }

  Future<void> _onBackgroundFetch(String taskId) async {
    await _performFetchTask();
    BackgroundFetch.finish(taskId);
  }

  void _onBackgroundFetchTimeout(String taskId) async {
    BackgroundFetch.finish(taskId);
  }

  Future<void> _performFetchTask() async {
    try {
      await scheduleNotifications();
    } catch (e) {
      Sentry.captureException(e);
    }
  }

  Future<void> scheduleNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS)) {
      if (prefs.getBool('syncWithICloud') ?? false) {
        await PersistenceController.instance.syncFromICloud();
        await PersistenceController.instance.syncToICloud();
      }
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
        if (subscription['date'] == null) continue;
        DateTime startDate = DateTime.parse(subscription['date']);
        DateTime nextBillDate = getNextBillDate(startDate, subscription['repeatPattern']);

        RememberCycle? cycle = RememberCycle.findByName(subscription['remembercycle']);
        DateTime notifyDate = nextBillDate;
        switch (cycle) {
          case RememberCycle.dayBefore:
            notifyDate = nextBillDate.subtract(const Duration(days: 1));
            break;
          case RememberCycle.twoDaysBefore:
            notifyDate = nextBillDate.subtract(const Duration(days: 2));
            break;
          case RememberCycle.weekBefore:
            notifyDate = nextBillDate.subtract(const Duration(days: 7));
            break;
          case RememberCycle.sameDay:
          default:
            break;
        }

        if (notifyDate.isBefore(now) || notifyDate.isAtSameMomentAs(now)) {
          continue;
        }

        String notificationTimeKey = DateFormat('yyyy-MM-dd').format(notifyDate);
        String notificationKey = 'notification_${subscription['id']}_$notificationTimeKey';
        bool alreadyNotified = prefs.getBool(notificationKey) ?? false;
        if (!alreadyNotified) {
          String body = S.current.subscriptionIsDueSoon(subscription['title']);
          if (prefs.getBool('includeCostInNotifications') ?? false) {
            body = S.current.subscriptionIsDueSoonWithPrice(subscription['title'], subscription['amount']);
          }
          String title = S.current.subscriptionReminder;
          await _showNotification(subscription, title, body);
          prefs.setBool(notificationKey, true);
        }
      }
    }
  }

  DateTime getNextBillDate(DateTime startDate, String repeatPattern) {
    DateTime nextBillDate = startDate;
    DateTime today = DateTime.now();
    if (repeatPattern == PaymentRate.yearly.value) {
      while (nextBillDate.isBefore(today)) {
        nextBillDate = DateTime(nextBillDate.year + 1, nextBillDate.month, nextBillDate.day);
      }
    } else if (repeatPattern == PaymentRate.monthly.value) {
      while (nextBillDate.isBefore(today)) {
        nextBillDate = DateTime(nextBillDate.year, nextBillDate.month + 1, nextBillDate.day);
      }
    }
    return nextBillDate;
  }


  Future<void> _showNotification(
      Map<String, dynamic> subscription, String title, String body) async {
    int notificationId =
        DateTime.now().millisecondsSinceEpoch.remainder(100000);
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'easy_wallet_channel_id',
      'EasyWallet',
      channelDescription: "EasyWallet App Notify Channel",
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      groupKey: groupKey,
      setAsGroupSummary: false,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

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
      Sentry.captureException(e);
    }
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
}

void backgroundFetchHeadlessTask(String taskId) async {
  final manager = BackgroundFetchManager();
  await manager._performFetchTask();
  BackgroundFetch.finish(taskId);
}
