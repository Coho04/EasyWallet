import 'package:easy_wallet/managers/background_task_manager.dart';
import 'package:easy_wallet/main_views/home_view.dart';
import 'package:easy_wallet/main_views/settings_view.dart';
import 'package:easy_wallet/main_views/statistic_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../generated/l10n.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    HomeView(),
    StatisticView(),
    SettingsView(),
  ];

  @override
  void initState() {
    super.initState();
    _checkAndRequestNotificationPermissions();
    _initNotifications();
  }

  void _checkAndRequestNotificationPermissions() async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

    final IOSFlutterLocalNotificationsPlugin? iosImplementation =
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

    iosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  void _initNotifications() async {
    final backgroundTaskManager = BackgroundTaskManager();
    await backgroundTaskManager.init();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.creditcard_fill),
            label: S.of(context).subscriptions,
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.chart_bar_fill),
            label: S.of(context).statistics,
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.settings),
            label: S.of(context).settings,
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (context) {
            return CupertinoPageScaffold(
              child: _widgetOptions[index],
            );
          },
        );
      },
    );
  }
}
