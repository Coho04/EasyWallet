import 'package:easy_wallet/generated/l10n.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:easy_wallet/provider/subscription_provider.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:easy_wallet/model/category.dart' as model;
import 'package:easy_wallet/class/data_transfer.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:easy_wallet/class/money.dart';
import 'package:easy_wallet/easy_wallet_app.dart';
import 'package:easy_wallet/enum/currency.dart';
import 'package:easy_wallet/persistence_controller.dart';
import 'package:easy_wallet/provider/currency_provider.dart';
import 'package:easy_wallet/views/components/auto_text.dart';
import 'package:easy_wallet/views/components/card_section_component.dart';
import 'package:easy_wallet/views/components/settings_row.dart';
import 'package:easy_wallet/views/components/gradient_header.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_wallet/managers/background_fetch_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
  String _appVersion = '';
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _appVersion = '${info.version} (${info.buildNumber})');
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

  Future<void> _saveSettings(BuildContext context) async {
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

    if (!context.mounted) return;
    await Provider.of<CurrencyProvider>(context, listen: false).loadCurrency();

    // Time, cost display and the master switch all change what should be
    // pending with the system.
    try {
      await BackgroundFetchManager().scheduleNotifications();
    } catch (e) {
      debugPrint('Could not reschedule notifications: $e');
    }
  }

  Future<bool> _authenticate() async {
    try {
      final bool authenticated = await auth.authenticate(
        localizedReason:
            Intl.message('pleaseAuthenticateYourselfToChangeThisSetting'),
        biometricOnly: true,
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
      if (!context.mounted) return;
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
    final textColor =
        isDarkMode ? CupertinoColors.white : CupertinoColors.black;

    return CupertinoPageScaffold(
      backgroundColor:
          CupertinoColors.systemGroupedBackground.resolveFrom(context),
      child: Column(
        children: [
          GradientHeader(
            title: Intl.message('settings'),
            showBackButton: false,
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
              CardSection(
                title: Intl.message('notifications'),
                children: [
                  SettingsRow.toggle(
                    label: Intl.message('enableNotifications'),
                    value: notificationsEnabled,
                    onChanged: _handleNotificationsToggle,
                  ),
                  SettingsRow.toggle(
                    label: Intl.message('includeCostInNotifications'),
                    value: includeCostInNotifications,
                    onChanged: (value) {
                      setState(() {
                        includeCostInNotifications = value;
                      });
                      _saveSettings(context);
                    },
                  ),
                  SettingsRow.value(
                    label: Intl.message('notificationTime'),
                    value: _formatTime(notificationTime),
                    onTap: () => _selectNotificationTime(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              CardSection(
                title: Intl.message('security'),
                children: [
                  SettingsRow.toggle(
                    label: Intl.message('enableAuthProtection'),
                    value: isAuthProtected,
                    onChanged: (value) =>
                        _handleAuthProtectionToggle(value, context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              CardSection(
                title: Intl.message('general'),
                children: [
                  SettingsRow.value(
                    label: Intl.message('currency'),
                    value: currency.name,
                    onTap: () => _selectCurrency(context),
                  ),
                  SettingsRow.value(
                    label: Intl.message('monthlyLimit'),
                    value: Money.format(monthlyLimit, currency.symbol),
                    onTap: () => _enterMonthlyLimit(context),
                  ),
                  SettingsRow.toggle(
                    label: Intl.message('displayCategories'),
                    value: displayCategories,
                    onChanged: (value) {
                      setState(() {
                        displayCategories = value;
                      });
                      _saveSettings(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              CardSection(
                title: Intl.message('dataManagement'),
                children: [
                  ..._buildPlatformSpecificSyncOptions(textColor: textColor),
                  SettingsRow.link(
                    label: Intl.message('exportData'),
                    onTap: _exportData,
                  ),
                  SettingsRow.link(
                    label: Intl.message('importData'),
                    onTap: _importData,
                  ),
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
              const SizedBox(height: 20),
              CardSection(
                title: Intl.message('about'),
                children: [
                  SettingsRow.info(
                    label: Intl.message('version'),
                    value: _appVersion,
                  ),
                ],
              ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPlatformSpecificSyncOptions({required Color textColor}) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return [
        SettingsRow.toggle(
          label: Intl.message('syncWithICloud'),
          value: syncWithICloud,
          onChanged: (bool value) {
            setState(() {
              syncWithICloud = value;
              syncWithGoogleDrive = value ? false : syncWithGoogleDrive;
            });
            _saveSettings(context);
          },
        ),
        SettingsRow.toggle(
          label: Intl.message('syncWithGoogleDrive'),
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
      ];
    } else {
      return [
        SettingsRow.toggle(
          label: Intl.message('syncWithGoogleDrive'),
          value: syncWithGoogleDrive,
          onChanged: (bool value) {
            handleGoogleSignIn(context, value);
            setState(() {
              syncWithGoogleDrive = value;
            });
            _saveSettings(context);
          },
        ),
      ];
    }
  }

  void handleGoogleSignIn(BuildContext context, bool enable) async {
    await PersistenceController.instance.googleDrive;
    if (enable) {
      try {
        await GoogleSignIn.instance.authenticate();
        PersistenceController.instance.syncWithCloud();
        displayMessage(
            title: Intl.message("successfully"),
            message: Intl.message("googleDriveLoginSuccess"));
      } catch (error) {
        displayMessage(
            title: Intl.message("error"),
            message: Intl.message("googleDriveLoginFailed"));
      }
    } else {
      await GoogleSignIn.instance.signOut();
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

/// Writes every subscription and category into a file the user picks. The
  /// app already syncs to iCloud and Drive, but nothing let people take their
  /// own copy out.
  Future<void> _exportData() async {
    try {
      final json = DataTransfer.encode(
        subscriptions: await Subscription.all(),
        categories: await model.Category.all(),
      );
      final stamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await FilePicker.saveFile(
        fileName: 'easywallet-$stamp.json',
        bytes: Uint8List.fromList(utf8.encode(json)),
        mimeType: 'application/json',
      );
    } catch (e) {
      Sentry.captureException(e);
      if (mounted) _showMessage(Intl.message('exportFailed'), '$e');
    }
  }

  /// Adds the contents of a backup. Existing entries are kept: the records are
  /// inserted as new ones, so an import can never destroy what is already
  /// there.
  Future<void> _importData() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (file == null) return;

      final backup = DataTransfer.decode(utf8.decode(await file.readAsBytes()));
      for (final category in backup.categories) {
        await model.Category(title: category.title, color: category.color)
            .save();
      }
      for (final subscription in backup.subscriptions) {
        subscription.id = null;
        await subscription.save();
      }

      if (!mounted) return;
      await Provider.of<SubscriptionProvider>(context, listen: false)
          .loadSubscriptions();
      if (!mounted) return;
      _showMessage(Intl.message('successfully'),
          S.of(context).importedCount(backup.subscriptions.length));
    } catch (e) {
      Sentry.captureException(e);
      if (mounted) _showMessage(Intl.message('importFailed'), '$e');
    }
  }

  void _showMessage(String title, String body) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(Intl.message('done')),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkActionButton(String text, String url) {
    return SettingsRow.link(
      label: Intl.message(text),
      onTap: () => _openWebPage(url, context),
    );
  }
}
