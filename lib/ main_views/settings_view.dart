import 'package:flutter/cupertino.dart';
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
  DateTime notificationTime = DateTime.now();
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
        final timeParts = notificationTimeString.split(':');
        notificationTime = DateTime(
          notificationTime.year,
          notificationTime.month,
          notificationTime.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
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
    prefs.setString('notificationTime',
        '${notificationTime.hour}:${notificationTime.minute}');
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
      showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Could not launch $url'),
            actions: <Widget>[
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  void _rateApp() {
    const url = "https://apps.apple.com/app/6478509715";
    _openWebPage(url);
  }

  Future<void> _selectNotificationTime(BuildContext context) async {
    final DateTime? picked = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 250,
          color: CupertinoColors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 180,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: notificationTime,
                  onDateTimeChanged: (DateTime newDateTime) {
                    setState(() {
                      notificationTime = newDateTime;
                    });
                    _saveSettings();
                  },
                ),
              ),
              CupertinoButton(
                child: const Text('Done'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
    if (picked != null && picked != notificationTime) {
      setState(() {
        notificationTime = picked;
      });
      _saveSettings();
    }
  }

  String _formatTime(DateTime time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Einstellungen'),
      ),
      child: ListView(
        children: [
          CupertinoFormSection.insetGrouped(
            header: const Text('Benachrichtigungen'),
            children: [
              CupertinoFormRow(
                prefix: const Text('Benachrichtigungen aktivieren'),
                child: CupertinoSwitch(
                  value: notificationsEnabled,
                  onChanged: _handleNotificationsToggle,
                ),
              ),
              CupertinoFormRow(
                prefix: const Text('Kosten in Benachrichtigungen anzeigen'),
                child: CupertinoSwitch(
                  value: includeCostInNotifications,
                  onChanged: (value) {
                    setState(() {
                      includeCostInNotifications = value;
                    });
                    _saveSettings();
                  },
                ),
              ),
              CupertinoFormRow(
                prefix: const Text('Benachrichtigungszeit'),
                child: GestureDetector(
                  onTap: () => _selectNotificationTime(context),
                  child: Text(
                    _formatTime(notificationTime),
                    style: const TextStyle(
                      color: CupertinoColors.systemBlue,
                    ),
                  ),
                ),
              ),
            ],
          ),
          CupertinoFormSection.insetGrouped(
            header: const Text('Einstellungen'),
            children: [
              CupertinoFormRow(
                prefix: const Text('Währung'),
                child: GestureDetector(
                  onTap: () {
                    // Implement currency selection dialog here
                  },
                  child: Text(
                    currency,
                    style: const TextStyle(
                      color: CupertinoColors.systemBlue,
                    ),
                  ),
                ),
              ),
              CupertinoFormRow(
                prefix: const Text('Monatliches Limit'),
                child: GestureDetector(
                  onTap: () {
                    // Implement monthly limit input here
                  },
                  child: Text(
                    '$monthlyLimit $currency',
                    style: const TextStyle(
                      color: CupertinoColors.systemBlue,
                    ),
                  ),
                ),
              ),
            ],
          ),
          CupertinoFormSection.insetGrouped(
            header: const Text('Support'),
            children: [
              CupertinoFormRow(
                child: GestureDetector(
                  onTap: () =>
                      _openWebPage("https://golden-developer.de/imprint"),
                  child: const Text(
                    'Impressum',
                    style: TextStyle(
                      color: CupertinoColors.systemBlue,
                    ),
                  ),
                ),
              ),
              CupertinoFormRow(
                child: GestureDetector(
                  onTap: () =>
                      _openWebPage("https://golden-developer.de/privacy"),
                  child: const Text(
                    'Datenschutz',
                    style: TextStyle(
                      color: CupertinoColors.systemBlue,
                    ),
                  ),
                ),
              ),
              CupertinoFormRow(
                child: GestureDetector(
                  onTap: () =>
                      _openWebPage("https://support.golden-developer.de"),
                  child: const Text(
                    'Hilfe',
                    style: TextStyle(
                      color: CupertinoColors.systemBlue,
                    ),
                  ),
                ),
              ),
              CupertinoFormRow(
                child: GestureDetector(
                  onTap: _rateApp,
                  child: const Text(
                    'Feedback',
                    style: TextStyle(
                      color: CupertinoColors.systemBlue,
                    ),
                  ),
                ),
              ),
              CupertinoFormRow(
                child: GestureDetector(
                  onTap: () =>
                      _openWebPage("https://support.golden-developer.de"),
                  child: const Text(
                    'Kontaktieren Sie den Entwickler',
                    style: TextStyle(
                      color: CupertinoColors.systemBlue,
                    ),
                  ),
                ),
              ),
              CupertinoFormRow(
                child: GestureDetector(
                  onTap: () =>
                      _openWebPage("https://donate.golden-developer.de"),
                  child: const Text(
                    'Trinkgeld Kasse',
                    style: TextStyle(
                      color: CupertinoColors.systemBlue,
                    ),
                  ),
                ),
              ),
              CupertinoFormRow(
                child: GestureDetector(
                  onTap: _rateApp,
                  child: const Text(
                    'Bewerten Sie die App',
                    style: TextStyle(
                      color: CupertinoColors.systemBlue,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
