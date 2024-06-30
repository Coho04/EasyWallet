import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  _SettingsViewState createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool notificationsEnabled = true;
  bool includeCostInNotifications = false;
  TimeOfDay notificationTime = TimeOfDay.now();
  String currency = "USD";
  double monthlyLimit = 0.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      includeCostInNotifications = prefs.getBool('includeCostInNotifications') ?? false;
      currency = prefs.getString('currency') ?? "USD";
      monthlyLimit = prefs.getDouble('monthlyLimit') ?? 0.0;
      final notificationTimeString = prefs.getString('notificationTime');
      if (notificationTimeString != null) {
        notificationTime = TimeOfDay(
          hour: int.parse(notificationTimeString.split(':')[0]),
          minute: int.parse(notificationTimeString.split(':')[1]),
        );
      }
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('notificationsEnabled', notificationsEnabled);
    prefs.setBool('includeCostInNotifications', includeCostInNotifications);
    prefs.setString('currency', currency);
    prefs.setDouble('monthlyLimit', monthlyLimit);
    prefs.setString('notificationTime', '${notificationTime.hour}:${notificationTime.minute}');
  }

  void _handleNotificationsToggle(bool isEnabled) {
    setState(() {
      notificationsEnabled = isEnabled;
    });
    _saveSettings();
  }

  Future<void> _openWebPage(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      // Show an error message if the URL could not be launched
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch $url'),
        ),
      );
    }
  }

  void _rateApp() {
    const url = "https://apps.apple.com/app/6478509715";
    _openWebPage(url);
  }

  Future<void> _selectNotificationTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: notificationTime,
    );
    if (picked != null && picked != notificationTime) {
      setState(() {
        notificationTime = picked;
      });
      _saveSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Enable Notifications'),
            value: notificationsEnabled,
            onChanged: _handleNotificationsToggle,
          ),
          SwitchListTile(
            title: const Text('Include Cost in Notifications'),
            value: includeCostInNotifications,
            onChanged: (value) {
              setState(() {
                includeCostInNotifications = value;
              });
              _saveSettings();
            },
          ),
          ListTile(
            title: const Text('Notification Time'),
            subtitle: Text(notificationTime.format(context)),
            trailing: const Icon(Icons.access_time),
            onTap: () => _selectNotificationTime(context),
          ),
          ListTile(
            title: const Text('Currency'),
            subtitle: Text(currency),
            onTap: () {
              // Implement currency selection dialog here
            },
          ),
          ListTile(
            title: const Text('Monthly Limit'),
            subtitle: Text('$monthlyLimit $currency'),
            onTap: () {
              // Implement monthly limit input here
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Imprint'),
            onTap: () => _openWebPage("https://golden-developer.de/imprint"),
          ),
          ListTile(
            title: const Text('Privacy Policy'),
            onTap: () => _openWebPage("https://golden-developer.de/privacy"),
          ),
          ListTile(
            title: const Text('Help'),
            onTap: () => _openWebPage("https://support.golden-developer.de"),
          ),
          ListTile(
            title: const Text('Feedback'),
            onTap: _rateApp,
          ),
          ListTile(
            title: const Text('Contact Developer'),
            onTap: () => _openWebPage("https://support.golden-developer.de"),
          ),
          ListTile(
            title: const Text('Tip Jar'),
            onTap: () => _openWebPage("https://donate.golden-developer.de"),
          ),
          ListTile(
            title: const Text('Rate the App'),
            onTap: _rateApp,
          ),
        ],
      ),
    );
  }
}
