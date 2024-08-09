import 'dart:async';
import 'package:easy_wallet/model/subscription.dart';
import 'package:flutter/foundation.dart';
import 'package:icloud_storage/icloud_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

import 'package:universal_io/io.dart';

class PersistenceController {
  static final PersistenceController instance =
      PersistenceController._internal();

  PersistenceController._internal();

  Database? _database;
  String icloudContainerId = 'iCloud.io.github.coho04.easywallet';
  String relativePath = 'easywallet/subscriptions_backup.json';
  String localFileName = 'subscriptions_backup.json';

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError("Database is not supported on the web");
    }
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'easywallet.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          '''
          CREATE TABLE subscriptions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            amount REAL,
            date TEXT,
            isPaused INTEGER,
            isPinned INTEGER,
            notes TEXT,
            remembercycle TEXT,
            repeating INTEGER,
            repeatPattern TEXT,
            timestamp TEXT,
            url TEXT
          )
          ''',
        );
      },
    );
  }

  Future<void> saveSubscription(Subscription subscription) async {
    if (kIsWeb) {
      throw UnsupportedError("Database is not supported on the web");
    }
    final db = await database;
    if (subscription.id == null) {
      await db.insert('subscriptions', subscription.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.update(
        'subscriptions',
        subscription.toJson(),
        where: 'id = ?',
        whereArgs: [subscription.id],
      );
    }
    await syncToICloud();
  }

  Future<void> deleteSubscription(Subscription subscription) async {
    if (kIsWeb) {
      throw UnsupportedError("Database is not supported on the web");
    }
    final db = await database;
    await db.delete(
      'subscriptions',
      where: 'id = ?',
      whereArgs: [subscription.id],
    );
    await syncToICloud();
  }

  Future<List<Subscription>> getAllSubscriptions() async {
    if (kIsWeb) {
      throw UnsupportedError("Database is not supported on the web");
    }
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('subscriptions');
    return List.generate(maps.length, (i) {
      return Subscription.fromJson(maps[i]);
    });
  }

  Future<void> syncToICloud() async {
    try {
      final List<Subscription> subscriptions = await getAllSubscriptions();
      final String json = jsonEncode(subscriptions.map((s) => s.toJson()).toList());

      final directory = await getApplicationDocumentsDirectory();
      final File file = File('${directory.path}/$localFileName');
      await file.writeAsString(json);

      await ICloudStorage.upload(
        containerId: icloudContainerId,
        filePath: file.path,
        destinationRelativePath: relativePath,
        onProgress: (stream) {
          stream.listen(
                (progress) => debugPrint('Upload File Progress: $progress'),
            onDone: () => debugPrint('Upload File Done'),
            onError: (err) => debugPrint('Upload File Error: $err'),
            cancelOnError: true,
          );
        },
      );
    } catch (e) {
      debugPrint("Error syncing to iCloud: $e");
    }
  }

  Future<void> syncFromICloud() async {
    final directory = await getApplicationDocumentsDirectory();
    final localFilePath = join(directory.path, localFileName);
    try {
      await ICloudStorage.download(
        containerId: icloudContainerId,
        relativePath: relativePath,
        destinationFilePath: localFilePath,
        onProgress: (stream) {
          stream.listen(
                (progress) => debugPrint('Download File Progress: $progress'),
            onDone: () async {
              debugPrint('Download File Done');
              await readFile(localFilePath);
            },
            onError: (err) => debugPrint('Download File Error: $err'),
            cancelOnError: true,
          );
        },
      );
    } catch (e) {
      debugPrint("Error syncing from iCloud: $e");
    }
  }

  Future<void> readFile(String localFilePath) async {
    try {
      final File file = File(localFilePath);
      if (!file.existsSync()) {
        debugPrint("File does not exist: $localFilePath");
        return;
      }

      final String json = await file.readAsString();
      if (json.isNotEmpty) {
        final List<dynamic> data = jsonDecode(json);
        final db = await database;
        debugPrint("Syncing from iCloud: ${data.length} items");
        for (var item in data) {
          await db.insert('subscriptions', Map<String, dynamic>.from(item),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await file.delete();
      } else {
        debugPrint("Downloaded file is empty");
      }
    } catch (e) {
      debugPrint("Error reading file from iCloud: $e");
    }
  }
}
