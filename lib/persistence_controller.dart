import 'dart:async';
import 'package:easy_wallet/model/subscription.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class PersistenceController {
  static final PersistenceController instance = PersistenceController._internal();

  PersistenceController._internal();

  Database? _database;

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError("Sqflite is not supported on the web");
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
      throw UnsupportedError("Sqflite is not supported on the web");
    }
    final db = await database;
    if (subscription.id == null) {
      await db.insert('subscriptions', subscription.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.update(
        'subscriptions',
        subscription.toJson(),
        where: 'id = ?',
        whereArgs: [subscription.id],
      );
    }
  }

  Future<void> deleteSubscription(Subscription subscription) async {
    if (kIsWeb) {
      throw UnsupportedError("Sqflite is not supported on the web");
    }
    final db = await database;
    await db.delete(
      'subscriptions',
      where: 'id = ?',
      whereArgs: [subscription.id],
    );
  }

  Future<List<Subscription>> getAllSubscriptions() async {
    if (kIsWeb) {
      throw UnsupportedError("Sqflite is not supported on the web");
    }
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('subscriptions');

    return List.generate(maps.length, (i) {
      return Subscription.fromJson(maps[i]);
    });
  }
}
