import 'package:easy_wallet/provider/tour_provider.dart';
import 'package:easy_wallet/views/categories/index.dart';
import 'package:easy_wallet/views/components/tour_overlay.dart';
import 'package:easy_wallet/views/main/calendar.dart';
import 'package:easy_wallet/views/main/settings.dart';
import 'package:easy_wallet/views/main/statistic.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../generated/l10n.dart';
import '../subscription/index.dart';

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  MainViewState createState() => MainViewState();
}

class MainViewState extends State<MainView> {
  int _selectedIndex = 0;

  /// Owned here so the guided tour can move between tabs; without a controller
  /// the tab scaffold keeps the index to itself and only the user can change it.
  final CupertinoTabController _tabController = CupertinoTabController();

  late final TourController _tour;

  /// Whether the tour was running on the previous notification, so its end can
  /// be told apart from it never having started.
  bool _tourWasRunning = false;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  static final List<Widget> _widgetOptions = <Widget>[
    const SubscriptionIndexView(),
    const CategoryIndexView(),
    const CalendarView(),
    const StatisticView(),
    const SettingsView(),
  ];

  @override
  void initState() {
    super.initState();
    _checkAndRequestNotificationPermissions();

    _tour = context.read<TourController>();
    _tour.addListener(_followTour);
    // After the first frame: the tour puts a card over the tabs, and there
    // has to be something to put it over.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _tour.startIfUnseen();
      }
    });
  }

  @override
  void dispose() {
    _tour.removeListener(_followTour);
    _tabController.dispose();
    super.dispose();
  }

  /// Moves the tab bar along with the tour, and returns to the subscriptions
  /// once it is over — the tour ends on the settings, which is not where
  /// anybody wants to be left standing.
  void _followTour() {
    if (!mounted) {
      return;
    }
    final step = _tour.step;
    if (step == null) {
      if (_tourWasRunning) {
        _tourWasRunning = false;
        _selectTab(0);
      }
      return;
    }
    _tourWasRunning = true;
    _selectTab(step.tabIndex);
  }

  void _selectTab(int index) {
    // A step pointing at a tab that no longer exists would take the whole app
    // down with it: the tab controller asserts on an index it cannot show.
    // Ignoring the move leaves the tour running on the wrong screen, which is
    // a cosmetic problem rather than a crash.
    if (index < 0 || index >= _navigatorKeys.length) {
      return;
    }
    _tabController.index = index;
    setState(() {
      _selectedIndex = index;
    });
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

  void _onItemTapped(int index) {
    // The scaffold has already moved the controller by the time this runs, so
    // the previous tab is what _selectedIndex still holds.
    if (_selectedIndex == index) {
      _navigatorKeys[index].currentState!.popUntil((route) => route.isFirst);
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final step = context.watch<TourController>().step;

    return Stack(
      children: [
        CupertinoTabScaffold(
          controller: _tabController,
          tabBar: CupertinoTabBar(
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: const Icon(CupertinoIcons.creditcard_fill),
                label: S.of(context).subscriptions,
              ),
              BottomNavigationBarItem(
                icon: const Icon(CupertinoIcons.rectangle_3_offgrid_fill),
                label: S.of(context).categories,
              ),
              BottomNavigationBarItem(
                icon: const Icon(CupertinoIcons.calendar),
                label: S.of(context).calendar,
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
        ),
        if (step != null)
          TourOverlay(
            title: step.title(),
            body: step.body(),
            stepNumber: _tour.stepNumber,
            stepCount: _tour.stepCount,
            onNext: _tour.next,
            onSkip: _tour.finish,
          ),
      ],
    );
  }
}
