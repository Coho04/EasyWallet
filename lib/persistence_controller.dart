import 'dart:async';
import 'package:easy_wallet/cloud/google_drive.dart';
import 'package:easy_wallet/cloud/icloud.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:easy_wallet/model/category.dart' as category;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class PersistenceController {
  static PersistenceController instance = PersistenceController._internal();

  PersistenceController._internal();

  Database? _database;
  ICloud? _icloud;
  GoogleDrive? _googleDrive;

  Future<ICloud> get icloud async {
    if (kIsWeb) {
      throw UnsupportedError("Database is not supported on the web");
    }
    if (_icloud != null) return _icloud!;
    _icloud = ICloud(database: await database);
    return _icloud!;
  }

  Future<GoogleDrive> get googleDrive async {
    if (kIsWeb) {
      throw UnsupportedError("Database is not supported on the web");
    }
    if (_googleDrive != null) return _googleDrive!;
    _googleDrive = GoogleDrive(database: await database);
    return _googleDrive!;
  }

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

    return await openDatabase(path, version: 2, onCreate: (db, version) {
      db.execute('''
        CREATE TABLE IF NOT EXISTS categories(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          color TEXT NOT NULL
        )
        ''');

      return db.execute(
        '''
          CREATE TABLE IF NOT EXISTS subscriptions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            amount REAL,
            date TEXT,
            isPaused INTEGER DEFAULT NULL,
            isPinned INTEGER DEFAULT NULL,
            notes TEXT DEFAULT NULL,
            remembercycle TEXT DEFAULT NULL,
            repeating INTEGER DEFAULT NULL,
            repeatPattern TEXT DEFAULT NULL,
            timestamp TEXT DEFAULT NULL,
            url TEXT DEFAULT NULL,
            category_id INTEGER DEFAULT NULL,
            FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
          )
          ''',
      );
    }, onUpgrade: (Database db, int oldVersion, int newVersion) async {
      if (oldVersion < 2) {
        db.execute('''
          CREATE TABLE IF NOT EXISTS categories(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            color TEXT NOT NULL
          );
          ''');
        db.execute('''
          ALTER TABLE subscriptions ADD COLUMN category_id INTEGER;
          ALTER TABLE subscriptions ADD FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL;
          ''');
      }
    });
  }

  Future<void> syncWithCloud() async {
    if (kIsWeb) {
      throw UnsupportedError("Cloud Sync is not supported on the web");
    }
    final prefs = await SharedPreferences.getInstance();
    final List<Subscription> subscriptions = await Subscription.all();
    final List<category.Category> categories = await category.Category.all();
    if (prefs.getBool('syncWithICloud') ?? false) {
      var cloud = await icloud;
      await cloud.syncTo(subscriptions, categories);
      await cloud.syncFrom();
    }
    if (prefs.getBool('syncWithGoogleDrive') ?? false) {
      var cloud = await googleDrive;
      await cloud.syncTo(subscriptions, categories);
      await cloud.syncFrom();
    }
  }
}
