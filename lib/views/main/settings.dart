import 'package:easy_wallet/easy_wallet_app.dart';
import 'package:easy_wallet/enum/currency.dart';
import 'package:easy_wallet/persistence_controller.dart';
import 'package:easy_wallet/provider/currency_provider.dart';
import 'package:easy_wallet/views/components/auto_text.dart';
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
  bool displayCategories = true;
  bool syncWithICloud = false;
  bool syncWithGoogleDrive = false;
  DateTime notificationTime = DateTime.now();
  Currency currency = Currency.usd;
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
      syncWithGoogleDrive = prefs.getBool('syncWithGoogleDrive') ?? false;
      displayCategories = prefs.getBool('displayCategories') ?? false;
      currency = Currency.findByName(prefs.getString('currency') ?? 'USD');
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

  Future<void> _saveSettings(context) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('notificationsEnabled', notificationsEnabled);
    prefs.setBool('includeCostInNotifications', includeCostInNotifications);
    prefs.setBool('require_authentication', isAuthProtected);
    prefs.setBool('syncWithICloud', syncWithICloud);
    prefs.setBool('syncWithGoogleDrive', syncWithGoogleDrive);
    prefs.setString('currency', currency.name);
    prefs.setDouble('monthlyLimit', monthlyLimit);
    prefs.setBool('displayCategories', displayCategories);
    prefs.setString('notificationTime',
        '${notificationTime.hour}:${notificationTime.minute}');

    await Provider.of<CurrencyProvider>(context, listen: false).loadCurrency();
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

  bool syncWithCloud() {
    return !kIsWeb;
  }

  Future<void> _handleAuthProtectionToggle(bool isEnabled, context) async {
    if (await _authenticate()) {
      setState(() {
        isAuthProtected = isEnabled;
      });
      _saveSettings(context);
    } else {
      showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: AutoText(
              maxLines: 1,
              text: Intl.message('settings'),
            ),
            content: AutoText(
              maxLines: 1,
              text: Intl.message('settingsAuthFailed'),
            ),
            actions: <Widget>[
              CupertinoDialogAction(
                child: Text(
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
    _saveSettings(context);
  }

  Future<void> _openWebPage(String url, context) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: AutoText(
              text: Intl.message('error'),
            ),
            content: AutoText(
              text: '${Intl.message('couldNotLaunch')} $url',
            ),
            actions: <Widget>[
              CupertinoDialogAction(
                child: Text(
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

  String _rateApp() {
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS)) {
      return "https://apps.apple.com/app/6478509715";
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return "https://play.google.com/store/apps/details?id=io.github.coho04.easy_wallet&hl=en-US&ah=J1tEPS0kySDuv5GU5zVvWM_C_Ds";
    }
    return '';
  }

  Future<void> _selectNotificationTime(context) async {
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
                    _saveSettings(context);
                  },
                ),
              ),
              CupertinoButton(
                child: AutoText(
                  maxLines: 1,
                  text: Intl.message('done'),
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
      _saveSettings(context);
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
                  currency = Currency.findByName(value);
                });
                _saveSettings(context);
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
                _saveSettings(context);
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
          middle: Text(Intl.message('settings')),
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
                    prefix: Flexible(
                        flex: 2,
                        child: AutoText(
                            text: Intl.message('enableNotifications'),
                            maxLines: 2,
                            color: textColor)),
                    child: CupertinoSwitch(
                      value: notificationsEnabled,
                      onChanged: _handleNotificationsToggle,
                    ),
                  ),
                  CupertinoFormRow(
                    prefix: Flexible(
                      flex: 3,
                      child: AutoText(
                          text: Intl.message('includeCostInNotifications'),
                          maxLines: 3,
                          color: textColor),
                    ),
                    child: CupertinoSwitch(
                      value: includeCostInNotifications,
                      onChanged: (value) {
                        setState(() {
                          includeCostInNotifications = value;
                        });
                        _saveSettings(context);
                      },
                    ),
                  ),
                  CupertinoFormRow(
                    padding: const EdgeInsets.all(16),
                    prefix: AutoText(
                        maxLines: 1,
                        text: Intl.message('notificationTime'),
                        color: textColor),
                    child: GestureDetector(
                      onTap: () => _selectNotificationTime(context),
                      child: AutoText(
                          maxLines: 1,
                          text: _formatTime(notificationTime),
                          color: CupertinoColors.systemBlue),
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
                      child: AutoText(
                          text: Intl.message('enableAuthProtection'),
                          color: textColor),
                    ),
                    child: CupertinoSwitch(
                      value: isAuthProtected,
                      onChanged: (value) {
                        _handleAuthProtectionToggle(value, context);
                      },
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
                    prefix: AutoText(
                        maxLines: 1,
                        text: Intl.message('currency'),
                        color: textColor),
                    child: GestureDetector(
                      onTap: () => _selectCurrency(context),
                      child: AutoText(
                          maxLines: 1,
                          text: currency.name,
                          color: CupertinoColors.systemBlue),
                    ),
                  ),
                  CupertinoFormRow(
                    padding: const EdgeInsets.all(16),
                    prefix: AutoText(
                        maxLines: 1,
                        text: Intl.message('monthlyLimit'),
                        color: textColor),
                    child: GestureDetector(
                      onTap: () => _enterMonthlyLimit(context),
                      child: AutoText(
                          maxLines: 1,
                          text: '$monthlyLimit ${currency.symbol}',
                          color: CupertinoColors.systemBlue),
                    ),
                  ),
                  CupertinoFormRow(
                    padding: const EdgeInsets.all(16),
                    prefix: AutoText(
                        maxLines: 1,
                        text: Intl.message('displayCategories'),
                        color: textColor),
                    child: CupertinoSwitch(
                      value: displayCategories,
                      onChanged: (value) {
                        setState(() {
                          displayCategories = value;
                        });
                        _saveSettings(context);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              CardSection(
                title: Intl.message('dataManagement'),
                children: [
                  ..._buildPlatformSpecificSyncOptions(textColor: textColor),
                ],
              ),
              const SizedBox(height: 20),
              CardSection(
                title: Intl.message('support'),
                children: [
                  _buildLinkActionButton(
                      'imprint', "https://golden-developer.de/imprint"),
                  _buildLinkActionButton(
                      'privacyPolicy', "https://golden-developer.de/privacy"),
                  _buildLinkActionButton(
                      'help', "https://support.golden-developer.de"),
                  _buildLinkActionButton('feedback', _rateApp()),
                  _buildLinkActionButton('contactDeveloper',
                      "https://support.golden-developer.de"),
                  _buildLinkActionButton(
                      'tipJar', 'https://donate.golden-developer.de'),
                  _buildLinkActionButton('rateApp', _rateApp()),
                ],
              ),
            ],
          ),
        ));
  }

  List<Widget> _buildPlatformSpecificSyncOptions({required Color textColor}) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return [
        CupertinoFormRow(
          padding: const EdgeInsets.all(16),
          prefix:
              AutoText(maxLines: 1, text: 'Sync with iCloud', color: textColor),
          child: CupertinoSwitch(
            value: syncWithICloud,
            onChanged: (bool value) {
              setState(() {
                syncWithICloud = value;
                syncWithGoogleDrive = value ? false : syncWithGoogleDrive;
              });
              _saveSettings(context);
            },
          ),
        ),
        CupertinoFormRow(
          prefix: AutoText(
              maxLines: 1, text: 'Sync with Google Drive', color: textColor),
          child: CupertinoSwitch(
            value: syncWithGoogleDrive,
            onChanged: (bool value) {
              handleGoogleSignIn(context, value);
              setState(() {
                syncWithGoogleDrive = value;
                syncWithICloud = value ? false : syncWithICloud;
              });
              _saveSettings(context);
            },
          ),
        ),
      ];
    } else {
      return [
        CupertinoFormRow(
          prefix: AutoText(
              maxLines: 1, text: 'Sync with Google Drive', color: textColor),
          child: CupertinoSwitch(
            value: syncWithGoogleDrive,
            onChanged: (bool value) {
              handleGoogleSignIn(context, value);
              setState(() {
                syncWithGoogleDrive = value;
              });
              _saveSettings(context);
            },
          ),
        ),
      ];
    }
  }

  void handleGoogleSignIn(BuildContext context, bool enable) async {
    var googleCloud = await PersistenceController.instance.googleDrive;
    if (enable) {
      try {
        final account = await googleCloud.googleSignIn.signIn();
        if (account != null) {
          if (await googleCloud.googleSignIn.isSignedIn()) {
            PersistenceController.instance.syncWithCloud();
            displayMessage(
                title: Intl.message("successfully"),
                message: Intl.message("googleDriveLoginSuccess"));
          } else {
            displayMessage(
                title: Intl.message("error"),
                message: Intl.message('googleDriveLoginFailed'));
          }
        }
      } catch (error) {
        displayMessage(
            title: Intl.message("error"),
            message: Intl.message("googleDriveLoginFailed"));
      }
    } else {
      await googleCloud.googleSignIn.signOut();
      displayMessage(
          title: Intl.message("successfully"),
          message: Intl.message("googleDriveLogoutSuccess"));
    }
  }

  void displayMessage({required String title, required String message}) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              isDefaultAction: true,
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

  Widget _buildLinkActionButton(String text, String url) {
    return CupertinoFormRow(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: () => _openWebPage(url, context),
        child: Align(
          alignment: Alignment.centerLeft,
          child: AutoText(
              maxLines: 1,
              text: Intl.message(text),
              color: CupertinoColors.systemBlue),
        ),
      ),
    );
  }
}
