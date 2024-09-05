import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';

import '../model/category.dart';
import '../model/subscription.dart';

class Cloud {

  String icloudContainerId = 'iCloud.io.github.coho04.easywallet';
  String localFileName = 'subscriptions_backup.json';
  String relativePath = 'easywallet/subscriptions_backup.json';
  Database database;

  Cloud({
    required this.database,
  });

  Future<void> verifyAndReadFile(String filePath, String type) async {
    try {
      final File file = File(filePath);
      if (!file.existsSync()) {
        debugPrint('$type file does not exist');
        return;
      }

      final String content = await file.readAsString();
      if (content.isEmpty) {
        debugPrint('$type file is empty');
        return;
      }

      final List<dynamic> dataList = jsonDecode(content);
      final Database db = database;
      switch (type) {
        case 'subscriptions.json':
          for (var item in dataList) {
            await db.insert('subscriptions', Subscription.fromJson(item).toJson(),
                conflictAlgorithm: ConflictAlgorithm.replace);
          }
          debugPrint('Subscriptions updated');
          break;
        case 'categories.json':
          for (var item in dataList) {
            await db.insert('categories', Category.fromJson(item).toJson(),
                conflictAlgorithm: ConflictAlgorithm.replace);
          }
          debugPrint('Categories updated');
          break;
        default:
          debugPrint('Unhandled file type: $type');
          break;
      }
      await file.delete();
    } catch (e) {
      debugPrint('Error processing $type file: $e');
    }
  }
}
