import 'package:easy_wallet/background_task_manager.dart';
import 'package:easy_wallet/views/main/home.dart';
import 'package:easy_wallet/views/main/settings.dart';
import 'package:easy_wallet/views/main/statistic.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../generated/l10n.dart';

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  MainViewState createState() => MainViewState();
}

class MainViewState extends State<MainView> {
  int _selectedIndex = 0;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

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
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

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
    if (_selectedIndex == index) {
      _navigatorKeys[index].currentState!.popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
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
          navigatorKey: _navigatorKeys[index],
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
