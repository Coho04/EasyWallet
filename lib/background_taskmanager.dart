import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class BackgroundTaskManager {
  static const String taskName = "de.golden-developer.easywallet.refresh";
  static const String lastNotificationKey = "LastNotificationScheduleDate";

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await _initNotifications();
    Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
    Workmanager().registerPeriodicTask(
      "1",
      taskName,
      frequency: Duration(hours: 24),
    );
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final IOSInitializationSettings initializationSettingsIOS =
        IOSInitializationSettings();
    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> scheduleNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final String today = formatter.format(DateTime.now());
    final String? lastScheduledDate = prefs.getString(lastNotificationKey);

    if (lastScheduledDate == today) {
      print("Notifications were already scheduled today. Skipping.");
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
        case 'OneDayBefore':
          eventDate = eventDate.subtract(Duration(days: 1));
          break;
        case 'TwoDaysBefore':
          eventDate = eventDate.subtract(Duration(days: 2));
          break;
        case 'OneWeekBefore':
          eventDate = eventDate.subtract(Duration(days: 7));
          break;
        case 'SameDay':
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
        AndroidNotificationDetails(
            'your_channel_id', 'your_channel_name', 'your_channel_description',
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
    // Implement your date calculation logic here
  }

  Future<Database> _openDatabase() async {
    return openDatabase(
      join(await getDatabasesPath(), 'easywallet.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE subscriptions(id INTEGER PRIMARY KEY, title TEXT, amount REAL, isPaused INTEGER, remembercycle TEXT)",
        );
      },
      version: 1,
    );
  }
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final manager = BackgroundTaskManager();
    await manager.scheduleNotifications();
    return Future.value(true);
  });
}
