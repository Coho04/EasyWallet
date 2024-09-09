import 'package:easy_wallet/model/subscription.dart';
import 'package:easy_wallet/persistence_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

class Category {
  int? id;
  String title;
  Color color;

  Category({
    this.id,
    required this.title,
    this.color = CupertinoColors.systemCyan,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'color': color.value,
    };
  }

  Future<List<Subscription>> getSubscriptions() async {
    final db = await PersistenceController.instance.database;
    final idResults = await db.query(
        'subscription_categories',
        columns: ['subscription_id'],
        where: 'category_id = ?',
        whereArgs: [id]
    );
    var ids = idResults.map((result) => result['subscription_id']).toList();
    if (ids.isEmpty) {
      return [];
    }

    var placeholders = List<String>.generate(ids.length, (_) => '?').join(', ');
    final List<Map<String, dynamic>> maps = await db.query(
        'subscriptions',
        where: 'id IN ($placeholders)',
        whereArgs: ids
    );
    return maps.map((map) => Subscription.fromJson(map)).toList();
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      title: json['title'],
      color: Color(int.parse(json['color'])),
    );
  }

  Future<void> save() async {
    if (kIsWeb) {
      throw UnsupportedError("Database is not supported on the web");
    }
    final db = await PersistenceController.instance.database;
    if (id == null) {
      await db.insert('categories', toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.update(
        'categories',
        toJson(),
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> delete() async {
    if (kIsWeb) {
      throw UnsupportedError("Database is not supported on the web");
    }
    final db = await PersistenceController.instance.database;
    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<List<Category>> all() async {
    if (kIsWeb) {
      throw UnsupportedError("Database is not supported on the web");
    }
    final db = await PersistenceController.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return List.generate(maps.length, (i) {
      return Category.fromJson(maps[i]);
    });
  }

  @override
  String toString() {
    return title;
  }
}

