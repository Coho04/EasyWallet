import 'package:easy_wallet/%20main_views/home_view.dart';
import 'package:easy_wallet/%20main_views/settings_view.dart';
import 'package:easy_wallet/%20main_views/statistic_view.dart';
import 'package:easy_wallet/background_task_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart';
import 'persistence_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
    onDidReceiveLocalNotification: onDidReceiveLocalNotification,
  );
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
    selectNotification(response.payload);
  });

  if (!kIsWeb) {
    Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
    final persistenceController = PersistenceController.instance;
    await persistenceController.database; // Ensure database is initialized
  }

  runApp(const EasyWalletApp());
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final manager = BackgroundTaskManager();
    await manager.scheduleNotifications();
    return Future.value(true);
  });
}

Future selectNotification(String? payload) async {
  // Handle notification tapped logic here
}

Future onDidReceiveLocalNotification(
    int id, String? title, String? body, String? payload) async {
  // Handle local notification received logic here
}

class EasyWalletApp extends StatelessWidget {
  const EasyWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'EasyWallet',
      theme: CupertinoThemeData(
        primaryColor: CupertinoColors.activeBlue,
      ),
      home: MainScreen(),
    );
  }
}

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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.creditcard_fill),
            label: 'Abonnements',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chart_bar_fill),
            label: 'Statistiken',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings),
            label: 'Einstellungen',
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
