import 'package:easy_wallet/managers/home_widget_bridge.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:easy_wallet/class/notification_plan.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:background_fetch/background_fetch.dart';

import '../generated/l10n.dart';
import '../persistence_controller.dart';

class BackgroundFetchManager {
  static const String groupKey = "com.easy_wallet.SUBSCRIPTION_NOTIFICATIONS";

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Every step stands on its own. Notifications and the home screen widgets
  /// have nothing to do with each other, so a device that refuses the one must
  /// not silently cost the user the other.
  Future<void> init() async {
    for (final step in <Future<void> Function()>[
      _initNotifications,
      _configureBackgroundFetch,
      // The reminders are handed over in advance, so they have to be built at
      // startup as well - not only when a background fetch happens to run.
      scheduleNotifications,
      HomeWidgetBridge.refresh,
    ]) {
      try {
        await step();
      } catch (e) {
        Sentry.captureException(e);
      }
    }
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      notificationCategories: [
        DarwinNotificationCategory(
          notificationCategory,
          actions: [
            DarwinNotificationAction.plain(
                pauseActionId, S.current.pauseSubscription),
          ],
        ),
      ],
      defaultPresentAlert: true,
      defaultPresentBanner: true,
      defaultPresentSound: true,
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          notificationResponseBackgroundHandler,
    );
    tzdata.initializeTimeZones();
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
    ).then((int status) {}).catchError((e) {
      Sentry.captureException(e);
    });

    BackgroundFetch.start().then((int status) {}).catchError((e) {
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
    // Two independent steps: a failing cloud sync must not stop the
    // reminders, which is what happened while the sync sat inside
    // scheduleNotifications().
    try {
      await PersistenceController.instance.syncWithCloud();
    } catch (e) {
      Sentry.captureException(e);
    }
    try {
      await scheduleNotifications();
    } catch (e) {
      Sentry.captureException(e);
    }
  }

  /// Hands the upcoming reminders to the operating system instead of firing
  /// them whenever a background fetch happens to run. The system delivers them
  /// at the exact time even if the app never wakes up.
  ///
  /// Everything pending is replaced on every run, so changed, paused, removed
  /// or expired subscriptions cannot leave a stale reminder behind.
  Future<void> scheduleNotifications() async {
    final prefs = await SharedPreferences.getInstance();

    // Nothing read this setting before, so switching notifications off in the
    // app did not actually stop them.
    if (!(prefs.getBool('notificationsEnabled') ?? true)) {
      await flutterLocalNotificationsPlugin.cancelAll();
      return;
    }

    final time = await _getUserNotificationTime();

    final plan = NotificationPlan.build(
      subscriptions: await Subscription.all(),
      now: DateTime.now(),
      hour: time.hour,
      minute: time.minute,
    );

    await flutterLocalNotificationsPlugin.cancelAll();

    final withPrice = prefs.getBool('includeCostInNotifications') ?? false;
    for (final notification in plan) {
      final String title;
      final String body;
      if (notification.isTrialEnd) {
        title = S.current.trialReminder;
        body = S.current.trialEndsSoon(notification.title);
      } else {
        title = S.current.subscriptionReminder;
        body = withPrice
            ? S.current.subscriptionIsDueSoonWithPrice(
                notification.title, notification.amount)
            : S.current.subscriptionIsDueSoon(notification.title);
      }
      await _scheduleNotification(notification, title, body);
    }
  }

  Future<void> _scheduleNotification(
      PlannedNotification notification, String title, String body) async {
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: notification.id,
        title: title,
        body: body,
        // from() keeps the instant, so the reminder lands at the configured
        // wall clock time even though tz.local is not set explicitly.
        scheduledDate: tz.TZDateTime.from(notification.at, tz.local),
        notificationDetails: _notificationDetails(),
        // Inexact avoids requiring the exact alarm permission on Android 12+;
        // a daily reminder does not need second precision.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: '${notification.subscriptionId}',
      );
    } catch (e) {
      Sentry.captureException(e);
    }
  }

  /// Acting on a reminder without opening the app first.
  static const String notificationCategory = 'easy_wallet_reminder';
  static const String pauseActionId = 'pause';

  Future<void> _onNotificationResponse(NotificationResponse response) async {
    await handleNotificationAction(response);
  }

  NotificationDetails _notificationDetails() {
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'easy_wallet_channel_id',
      'EasyWallet',
      channelDescription: "EasyWallet App Notify Channel",
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      groupKey: groupKey,
      setAsGroupSummary: false,
      icon: '@mipmap/ic_launcher',
      actions: [
        AndroidNotificationAction(pauseActionId, S.current.pauseSubscription),
      ],
    );

    const iosPlatformChannelSpecifics = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: notificationCategory,
    );

    return NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
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

/// Runs in its own isolate when the user acts on a reminder while the app is
/// closed, so it must not touch anything the UI owns.
@pragma('vm:entry-point')
void notificationResponseBackgroundHandler(NotificationResponse response) {
  handleNotificationAction(response);
}

/// Pauses the subscription the reminder belongs to and rebuilds what is
/// pending, so no further reminder arrives for it.
Future<void> handleNotificationAction(NotificationResponse response) async {
  if (response.actionId != BackgroundFetchManager.pauseActionId) {
    return;
  }
  final id = int.tryParse(response.payload ?? '');
  if (id == null) {
    return;
  }

  try {
    final subscriptions = await Subscription.all();
    final match = subscriptions.where((s) => s.id == id);
    if (match.isEmpty) {
      return;
    }
    final subscription = match.first;
    subscription.isPaused = true;
    await subscription.save();
    await BackgroundFetchManager().scheduleNotifications();
  } catch (e) {
    Sentry.captureException(e);
  }
}
