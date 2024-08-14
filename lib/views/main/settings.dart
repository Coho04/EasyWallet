import 'package:easy_wallet/easy_wallet_app.dart';
import 'package:easy_wallet/enum/currency.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  SettingsViewState createState() => SettingsViewState();
}

class SettingsViewState extends State<SettingsView> {
  bool notificationsEnabled = true;
  bool includeCostInNotifications = false;
  bool isAuthProtected = false; // Variable für Authentifizierungsschutz
  DateTime notificationTime = DateTime.now();
  String currency = Currency.USD.name;
  double monthlyLimit = 0.0;
  final LocalAuthentication auth = LocalAuthentication(); // LocalAuthentication-Instanz

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
      isAuthProtected = prefs.getBool('require_authentication') ?? false; // Laden der Authentifizierungseinstellung
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
    prefs.setBool('require_authentication', isAuthProtected);
    prefs.setString('currency', currency);
    prefs.setDouble('monthlyLimit', monthlyLimit);
    prefs.setString('notificationTime', '${notificationTime.hour}:${notificationTime.minute}');
  }

  Future<bool> _authenticate() async {
    try {
      final bool authenticated = await auth.authenticate(
        localizedReason: Intl.message('pleaseAuthenticateYourselfToChangeThisSetting'),
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );
      return authenticated;
    } on PlatformException catch (e) {
      return false;
    }
  }

  Future<void> _handleAuthProtectionToggle(bool isEnabled) async {
    if (await _authenticate()) {
      setState(() {
        isAuthProtected = isEnabled;
      });
      _saveSettings();
    }
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
            title: Text(
              Intl.message('error'),
              style: EasyWalletApp.responsiveTextStyle(16, context),
            ),
            content: Text(
              '${Intl.message('couldNotLaunch')} $url',
              style: EasyWalletApp.responsiveTextStyle(16, context),
            ),
            actions: <Widget>[
              CupertinoDialogAction(
                child: Text(
                  'OK',
                  style: EasyWalletApp.responsiveTextStyle(16, context),
                ),
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
    _openWebPage("https://apps.apple.com/app/6478509715");
  }

  Future<void> _selectNotificationTime(BuildContext context) async {
    final DateTime? picked = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 250,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              SizedBox(
                height: 180,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: notificationTime,
                  use24hFormat: true,
                  onDateTimeChanged: (DateTime newDateTime) {
                    setState(() {
                      notificationTime = newDateTime;
                    });
                    _saveSettings();
                  },
                ),
              ),
              CupertinoButton(
                child: Text(
                  Intl.message('done'),
                  style: EasyWalletApp.responsiveTextStyle(16, context),
                ),
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

  Future<void> _selectCurrency(BuildContext context) async {
    final List<String> currencies = Currency.all();
    await showCupertinoModalPopup<String>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: Text(
            Intl.message('selectCurrency'),
            style: EasyWalletApp.responsiveTextStyle(16, context),
          ),
          actions: currencies.map((String value) {
            return CupertinoActionSheetAction(
              child: Text(
                value,
                style: EasyWalletApp.responsiveTextStyle(16, context),
              ),
              onPressed: () {
                setState(() {
                  currency = value;
                });
                _saveSettings();
                Navigator.pop(context);
              },
            );
          }).toList(),
          cancelButton: CupertinoActionSheetAction(
            child: Text(
              Intl.message('cancel'),
              style: EasyWalletApp.responsiveTextStyle(16, context),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  Future<void> _enterMonthlyLimit(BuildContext context) async {
    final TextEditingController limitController = TextEditingController(text: monthlyLimit.toString());
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: Text(
            Intl.message('enterMonthlyLimit'),
            style: EasyWalletApp.responsiveTextStyle(16, context),
          ),
          message: CupertinoTextField(
            controller: limitController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            placeholder: Intl.message('monthlyLimit'),
          ),
          actions: <CupertinoActionSheetAction>[
            CupertinoActionSheetAction(
              child: Text(
                Intl.message('save'),
                style: EasyWalletApp.responsiveTextStyle(16, context),
              ),
              onPressed: () {
                setState(() {
                  monthlyLimit = double.tryParse(limitController.text) ?? 0.0;
                });
                _saveSettings();
                Navigator.pop(context);
              },
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: Text(
              Intl.message('cancel'),
              style: EasyWalletApp.responsiveTextStyle(16, context),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final backgroundColor = isDarkMode ? CupertinoColors.darkBackgroundGray : CupertinoColors.white;
    final textColor = isDarkMode ? CupertinoColors.white : CupertinoColors.black;
    final sectionHeaderColor = isDarkMode ? CupertinoColors.inactiveGray : CupertinoColors.systemGrey;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          Intl.message('settings'),
          style: EasyWalletApp.responsiveTextStyle(24, context, color: textColor),
        ),
        backgroundColor: backgroundColor,
      ),
      child: Container(
        color: backgroundColor,
        child: ListView(
          children: [
            CupertinoFormSection.insetGrouped(
              header: Text(
                Intl.message('notifications'),
                style: EasyWalletApp.responsiveTextStyle(16, context, color: sectionHeaderColor),
              ),
              children: [
                CupertinoFormRow(
                  prefix: Text(
                    Intl.message('enableNotifications'),
                    style: EasyWalletApp.responsiveTextStyle(16, context, color: textColor),
                  ),
                  child: CupertinoSwitch(
                    value: notificationsEnabled,
                    onChanged: _handleNotificationsToggle,
                  ),
                ),
                CupertinoFormRow(
                  prefix: Flexible(
                    child: Text(
                      Intl.message('includeCostInNotifications'),
                      style: EasyWalletApp.responsiveTextStyle(16, context, color: textColor),
                      softWrap: true,
                    ),
                  ),
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
                  padding: const EdgeInsets.all(16),
                  prefix: Text(
                    Intl.message('notificationTime'),
                    style: EasyWalletApp.responsiveTextStyle(16, context, color: textColor),
                  ),
                  child: GestureDetector(
                    onTap: () => _selectNotificationTime(context),
                    child: Text(
                      _formatTime(notificationTime),
                      style: EasyWalletApp.responsiveTextStyle(16, context, color: CupertinoColors.systemBlue),
                    ),
                  ),
                ),
              ],
            ),
            CupertinoFormSection.insetGrouped(
              header: Text(
                Intl.message('security'),
                style: EasyWalletApp.responsiveTextStyle(16, context, color: sectionHeaderColor),
              ),
              children: [
                CupertinoFormRow(
                  prefix: Expanded(
                    child: Text(
                      Intl.message('enableAuthProtection'),
                      style: EasyWalletApp.responsiveTextStyle(16, context, color: textColor),
                      softWrap: true,
                      maxLines: null,
                    ),
                  ),
                  child: CupertinoSwitch(
                    value: isAuthProtected,
                    onChanged: _handleAuthProtectionToggle,
                  ),
                ),
              ],
            ),
            CupertinoFormSection.insetGrouped(
              header: Text(
                Intl.message('settings'),
                style: EasyWalletApp.responsiveTextStyle(20, context, color: sectionHeaderColor),
              ),
              children: [
                CupertinoFormRow(
                  padding: const EdgeInsets.all(16),
                  prefix: Text(
                    Intl.message('currency'),
                    style: EasyWalletApp.responsiveTextStyle(16, context, color: textColor),
                  ),
                  child: GestureDetector(
                    onTap: () => _selectCurrency(context),
                    child: Text(
                      currency,
                      style: EasyWalletApp.responsiveTextStyle(16, context, color: CupertinoColors.systemBlue),
                    ),
                  ),
                ),
                CupertinoFormRow(
                  padding: const EdgeInsets.all(16),
                  prefix: Text(
                    Intl.message('monthlyLimit'),
                    style: EasyWalletApp.responsiveTextStyle(16, context, color: textColor),
                  ),
                  child: GestureDetector(
                    onTap: () => _enterMonthlyLimit(context),
                    child: Text(
                      '$monthlyLimit $currency',
                      style: EasyWalletApp.responsiveTextStyle(16, context, color: CupertinoColors.systemBlue),
                    ),
                  ),
                ),
              ],
            ),
            CupertinoFormSection.insetGrouped(
              header: Text(
                Intl.message('support'),
                style: EasyWalletApp.responsiveTextStyle(16, context, color: sectionHeaderColor),
              ),
              children: [
                CupertinoFormRow(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: () => _openWebPage("https://golden-developer.de/imprint"),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        Intl.message('imprint'),
                        style: EasyWalletApp.responsiveTextStyle(16, context, color: CupertinoColors.systemBlue),
                      ),
                    ),
                  ),
                ),
                CupertinoFormRow(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: () => _openWebPage("https://golden-developer.de/privacy"),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        Intl.message('privacyPolicy'),
                        style: EasyWalletApp.responsiveTextStyle(16, context, color: CupertinoColors.systemBlue),
                      ),
                    ),
                  ),
                ),
                CupertinoFormRow(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: () => _openWebPage("https://support.golden-developer.de"),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        Intl.message('help'),
                        style: EasyWalletApp.responsiveTextStyle(16, context, color: CupertinoColors.systemBlue),
                      ),
                    ),
                  ),
                ),
                CupertinoFormRow(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: _rateApp,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        Intl.message('feedback'),
                        style: EasyWalletApp.responsiveTextStyle(16, context, color: CupertinoColors.systemBlue),
                      ),
                    ),
                  ),
                ),
                CupertinoFormRow(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: () => _openWebPage("https://support.golden-developer.de"),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        Intl.message('contactDeveloper'),
                        style: EasyWalletApp.responsiveTextStyle(16, context, color: CupertinoColors.systemBlue),
                      ),
                    ),
                  ),
                ),
                CupertinoFormRow(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: () => _openWebPage("https://donate.golden-developer.de"),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        Intl.message('tipJar'),
                        style: EasyWalletApp.responsiveTextStyle(16, context, color: CupertinoColors.systemBlue),
                      ),
                    ),
                  ),
                ),
                CupertinoFormRow(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: _rateApp,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        Intl.message('rateApp'),
                        style: EasyWalletApp.responsiveTextStyle(16, context, color: CupertinoColors.systemBlue),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
