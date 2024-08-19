import 'package:auto_size_text/auto_size_text.dart';
import 'package:easy_wallet/easy_wallet_app.dart';
import 'package:easy_wallet/enum/currency.dart';
import 'package:easy_wallet/provider/currency_provider.dart';
import 'package:easy_wallet/views/components/card_section_component.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  SettingsViewState createState() => SettingsViewState();
}

class SettingsViewState extends State<SettingsView> {
  bool notificationsEnabled = true;
  bool includeCostInNotifications = false;
  bool isAuthProtected = false;
  bool syncWithICloud = false;
  DateTime notificationTime = DateTime.now();
  String currency = Currency.USD.name;
  double monthlyLimit = 0.0;
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      includeCostInNotifications =
          prefs.getBool('includeCostInNotifications') ?? false;
      isAuthProtected = prefs.getBool('require_authentication') ?? false;
      syncWithICloud = prefs.getBool('syncWithICloud') ?? false;
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
    prefs.setBool('syncWithICloud', syncWithICloud);
    prefs.setString('currency', currency);
    prefs.setDouble('monthlyLimit', monthlyLimit);
    prefs.setString('notificationTime',
        '${notificationTime.hour}:${notificationTime.minute}');

    await Provider.of<CurrencyProvider>(context, listen: false)
        .loadCurrency();
  }

  Future<bool> _authenticate() async {
    try {
      final bool authenticated = await auth.authenticate(
        localizedReason:
            Intl.message('pleaseAuthenticateYourselfToChangeThisSetting'),
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );
      return authenticated;
    } on PlatformException {
      return false;
    }
  }

  Future<void> _handleAuthProtectionToggle(bool isEnabled) async {
    if (await _authenticate()) {
      setState(() {
        isAuthProtected = isEnabled;
      });
      _saveSettings();
    } else {
      showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: AutoSizeText(
              maxLines: 1,
              Intl.message('settings'),
              style: EasyWalletApp.responsiveTextStyle(context),
            ),
            content: AutoSizeText(
              maxLines: 1,
              Intl.message('settingsAuthFailed'),
              style: EasyWalletApp.responsiveTextStyle(context),
            ),
            actions: <Widget>[
              CupertinoDialogAction(
                child: AutoSizeText(
                  maxLines: 1,
                  'OK',
                  style: EasyWalletApp.responsiveTextStyle(context),
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

  void _handleNotificationsToggle(bool isEnabled) {
    setState(() {
      notificationsEnabled = isEnabled;
    });
    _saveSettings();
  }

  void _handleICloudToggle(bool isEnabled) {
    setState(() {
      syncWithICloud = isEnabled;
    });
    _saveSettings();
  }

  Future<void> _openWebPage(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: AutoSizeText(
              maxLines: 1,
              Intl.message('error'),
              style: EasyWalletApp.responsiveTextStyle(context),
            ),
            content: AutoSizeText(
              maxLines: 1,
              '${Intl.message('couldNotLaunch')} $url',
              style: EasyWalletApp.responsiveTextStyle(context),
            ),
            actions: <Widget>[
              CupertinoDialogAction(
                child: AutoSizeText(
                  maxLines: 1,
                  'OK',
                  style: EasyWalletApp.responsiveTextStyle(context),
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
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS)) {
      _openWebPage("https://apps.apple.com/app/6478509715");
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      _openWebPage(
          "https://play.google.com/store/apps/details?id=io.github.coho04.easy_wallet&hl=en-US&ah=J1tEPS0kySDuv5GU5zVvWM_C_Ds");
    }
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
                child: AutoSizeText(
                  maxLines: 1,
                  Intl.message('done'),
                  style: EasyWalletApp.responsiveTextStyle(context),
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
            style: EasyWalletApp.responsiveTextStyle(context),
          ),
          actions: currencies.map((String value) {
            return CupertinoActionSheetAction(
              child: Text(
                value,
                style: EasyWalletApp.responsiveTextStyle(context),
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
              style: EasyWalletApp.responsiveTextStyle(context),
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
    final TextEditingController limitController =
        TextEditingController(text: monthlyLimit.toString());
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: Text(
            Intl.message('enterMonthlyLimit'),
            style: EasyWalletApp.responsiveTextStyle(context),
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
                style: EasyWalletApp.responsiveTextStyle(context),
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
              style: EasyWalletApp.responsiveTextStyle(context),
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
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final backgroundColor = isDarkMode
        ? CupertinoColors.darkBackgroundGray
        : CupertinoColors.systemBackground;
    final textColor =
        isDarkMode ? CupertinoColors.white : CupertinoColors.black;

    return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: AutoSizeText(
            maxLines: 1,
            Intl.message('settings'),
            style: EasyWalletApp.responsiveTextStyle(context,
                color: textColor),
          ),
          backgroundColor: backgroundColor,
        ),
        backgroundColor:
            CupertinoColors.systemGroupedBackground.resolveFrom(context),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              CardSection(
                title: Intl.message('notifications'),
                children: [
                  CupertinoFormRow(
                    prefix: AutoSizeText(
                      maxLines: 1,
                      Intl.message('enableNotifications'),
                      style: EasyWalletApp.responsiveTextStyle(context,
                          color: textColor),
                    ),
                    child: CupertinoSwitch(
                      value: notificationsEnabled,
                      onChanged: _handleNotificationsToggle,
                    ),
                  ),
                  CupertinoFormRow(
                    prefix: Flexible(
                      child: AutoSizeText(
                        maxLines: 2,
                        Intl.message('includeCostInNotifications'),
                        style: EasyWalletApp.responsiveTextStyle(context,
                            color: textColor),
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
                    prefix: AutoSizeText(
                      maxLines: 1,
                      Intl.message('notificationTime'),
                      style: EasyWalletApp.responsiveTextStyle(context,
                          color: textColor),
                    ),
                    child: GestureDetector(
                      onTap: () => _selectNotificationTime(context),
                      child: AutoSizeText(
                        maxLines: 1,
                        _formatTime(notificationTime),
                        style: EasyWalletApp.responsiveTextStyle(context,
                            color: CupertinoColors.systemBlue),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              CardSection(
                title: Intl.message('security'),
                children: [
                  CupertinoFormRow(
                    prefix: Expanded(
                      flex: 4,
                      child: AutoSizeText(
                        Intl.message('enableAuthProtection'),
                        style: EasyWalletApp.responsiveTextStyle(context,
                            color: textColor),
                      ),
                    ),
                    child: CupertinoSwitch(
                      value: isAuthProtected,
                      onChanged: _handleAuthProtectionToggle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              CardSection(
                title: Intl.message('settings'),
                children: [
                  CupertinoFormRow(
                    padding: const EdgeInsets.all(16),
                    prefix: AutoSizeText(
                      maxLines: 1,
                      Intl.message('currency'),
                      style: EasyWalletApp.responsiveTextStyle(context,
                          color: textColor),
                    ),
                    child: GestureDetector(
                      onTap: () => _selectCurrency(context),
                      child: AutoSizeText(
                        maxLines: 1,
                        currency,
                        style: EasyWalletApp.responsiveTextStyle(context,
                            color: CupertinoColors.systemBlue),
                      ),
                    ),
                  ),
                  CupertinoFormRow(
                    padding: const EdgeInsets.all(16),
                    prefix: AutoSizeText(
                      maxLines: 1,
                      Intl.message('monthlyLimit'),
                      style: EasyWalletApp.responsiveTextStyle(context,
                          color: textColor),
                    ),
                    child: GestureDetector(
                      onTap: () => _enterMonthlyLimit(context),
                      child: AutoSizeText(
                        maxLines: 1,
                        '$monthlyLimit $currency',
                        style: EasyWalletApp.responsiveTextStyle(context,
                            color: CupertinoColors.systemBlue),
                      ),
                    ),
                  ),
                ],
              ),
              if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS))
                const SizedBox(height: 20),
              if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS))
                CardSection(
                  title: Intl.message('dataManagement'),
                  children: [
                    CupertinoFormRow(
                      prefix: AutoSizeText(
                        maxLines: 1,
                        Intl.message('syncWithICloud'),
                        style: EasyWalletApp.responsiveTextStyle(context,
                            color: textColor),
                      ),
                      child: CupertinoSwitch(
                        value: syncWithICloud,
                        onChanged: _handleICloudToggle,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              CardSection(
                title: Intl.message('support'),
                children: [
                  CupertinoFormRow(
                    padding: const EdgeInsets.all(16),
                    child: GestureDetector(
                      onTap: () =>
                          _openWebPage("https://golden-developer.de/imprint"),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AutoSizeText(
                          maxLines: 1,
                          Intl.message('imprint'),
                          style: EasyWalletApp.responsiveTextStyle(context,
                              color: CupertinoColors.systemBlue),
                        ),
                      ),
                    ),
                  ),
                  CupertinoFormRow(
                    padding: const EdgeInsets.all(16),
                    child: GestureDetector(
                      onTap: () =>
                          _openWebPage("https://golden-developer.de/privacy"),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AutoSizeText(
                          maxLines: 1,
                          Intl.message('privacyPolicy'),
                          style: EasyWalletApp.responsiveTextStyle(context,
                              color: CupertinoColors.systemBlue),
                        ),
                      ),
                    ),
                  ),
                  CupertinoFormRow(
                    padding: const EdgeInsets.all(16),
                    child: GestureDetector(
                      onTap: () =>
                          _openWebPage("https://support.golden-developer.de"),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AutoSizeText(
                          maxLines: 1,
                          Intl.message('help'),
                          style: EasyWalletApp.responsiveTextStyle(context,
                              color: CupertinoColors.systemBlue),
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
                        child: AutoSizeText(
                          maxLines: 1,
                          Intl.message('feedback'),
                          style: EasyWalletApp.responsiveTextStyle(context,
                              color: CupertinoColors.systemBlue),
                        ),
                      ),
                    ),
                  ),
                  CupertinoFormRow(
                    padding: const EdgeInsets.all(16),
                    child: GestureDetector(
                      onTap: () =>
                          _openWebPage("https://support.golden-developer.de"),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AutoSizeText(
                          maxLines: 1,
                          Intl.message('contactDeveloper'),
                          style: EasyWalletApp.responsiveTextStyle(context,
                              color: CupertinoColors.systemBlue),
                        ),
                      ),
                    ),
                  ),
                  CupertinoFormRow(
                    padding: const EdgeInsets.all(16),
                    child: GestureDetector(
                      onTap: () =>
                          _openWebPage("https://donate.golden-developer.de"),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AutoSizeText(
                          maxLines: 1,
                          Intl.message('tipJar'),
                          style: EasyWalletApp.responsiveTextStyle(context,
                              color: CupertinoColors.systemBlue),
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
                        child: AutoSizeText(
                          maxLines: 1,
                          Intl.message('rateApp'),
                          style: EasyWalletApp.responsiveTextStyle(context,
                              color: CupertinoColors.systemBlue),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ));
  }
}
