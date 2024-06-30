import 'package:easy_wallet/%20main_views/home_view.dart';
import 'package:easy_wallet/%20main_views/settings_view.dart';
import 'package:easy_wallet/background_task_manager.dart';
import 'package:easy_wallet/%20main_views/statistic_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart'; // Import for kIsWeb
import 'persistence_controller.dart'; // Import the PersistenceController

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
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

class EasyWalletApp extends StatelessWidget {
  const EasyWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EasyWallet',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MainScreen(), // Use MainScreen as home
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
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
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Statistics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}
