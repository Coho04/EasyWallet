import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:easy_wallet/persistence_controller.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DataMigrationManager {
  static const platform = MethodChannel('com.example.easywallet/migration');

  Future<void> migrateData() async {
    final firstLaunch = await _checkFirstLaunch();
    if (firstLaunch) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final isMigrationDone = prefs.getBool('isMigrationDone') ?? false;
    if (isMigrationDone) {
      return;
    }

    try {
      await platform.invokeMethod('exportCoreDataToJSON');
      final directory = await getApplicationDocumentsDirectory();
      final jsonFilePath = '${directory.path}/subscriptions.json';

      final file = File(jsonFilePath);
      if (await file.exists()) {
        final jsonData = await file.readAsString();
        final List<dynamic> data = jsonDecode(jsonData);

        final persistenceController = PersistenceController.instance;

        for (var item in data) {
          final Map<String, dynamic> subscriptionJson = item;
          final subscription = Subscription.migrate(subscriptionJson);
          await persistenceController.saveSubscription(subscription);
        }

        await prefs.setBool('isMigrationDone', true);
      }
    } on PlatformException catch (e) {
      if (kDebugMode) {
        Sentry.captureException(e);
      }
    }
  }




  Future<bool> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final savedVersion = prefs.getString('app_version');
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    if (savedVersion == null) {
      await prefs.setString('app_version', currentVersion);
      return true;
    } else if (savedVersion != currentVersion) {
      await prefs.setString('app_version', currentVersion);
    }
    return false;
  }
}
