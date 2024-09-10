import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_wallet/enum/currency.dart';
import 'package:easy_wallet/enum/payment_rate.dart';
import 'package:easy_wallet/enum/remember_cycle.dart';
import 'package:easy_wallet/persistence_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:sqflite/sqflite.dart';
import 'package:easy_wallet/model/category.dart' as category;

class Subscription {
  int? id;
  double amount;
  DateTime? date;
  bool isPaused;
  bool isPinned;
  String? notes;
  String? rememberCycle;
  bool repeating;
  String? repeatPattern;
  DateTime? timestamp;
  String title;
  String? url;

  Subscription({
    this.id,
    required this.amount,
    this.date,
    required this.isPaused,
    required this.isPinned,
    this.notes,
    this.rememberCycle,
    required this.repeating,
    this.repeatPattern,
    this.timestamp,
    required this.title,
    this.url,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'date': date?.toIso8601String(),
      'isPaused': isPaused ? 1 : 0,
      'isPinned': isPinned ? 1 : 0,
      'notes': notes,
      'rememberCycle': rememberCycle,
      'repeating': repeating ? 1 : 0,
      'repeatPattern': repeatPattern,
      'timestamp': timestamp?.toIso8601String(),
      'title': title,
      'url': url,
    };
  }

  int remainingDays() {
    if (date == null) return 0;
    DateTime nextBillDate = date!;
    DateTime today = DateTime.now();
    DateTime todayDateOnly = DateTime(today.year, today.month, today.day);

    if (repeatPattern == PaymentRate.yearly.value) {
      while (nextBillDate.isBefore(todayDateOnly) ||
          nextBillDate.isAtSameMomentAs(todayDateOnly)) {
        nextBillDate = DateTime(
            nextBillDate.year + 1, nextBillDate.month, nextBillDate.day);
      }
    } else if (repeatPattern == PaymentRate.monthly.value) {
      while (nextBillDate.isBefore(todayDateOnly) ||
          nextBillDate.isAtSameMomentAs(todayDateOnly)) {
        nextBillDate = DateTime(
            nextBillDate.year, nextBillDate.month + 1, nextBillDate.day);
        while (
            !DateTime(nextBillDate.year, nextBillDate.month, nextBillDate.day)
                .isValidDate()) {
          nextBillDate = DateTime(
              nextBillDate.year, nextBillDate.month, nextBillDate.day - 1);
        }
      }
    }
    return nextBillDate.difference(todayDateOnly).inDays;
  }

  double? convertPrice() {
    if (repeatPattern == PaymentRate.yearly.value) {
      return (amount / 12);
    } else if (repeatPattern == PaymentRate.monthly.value) {
      return (amount * 12);
    }
    return null;
  }

  DateTime? calculatePreviousBillDate() {
    if (date == null || repeatPattern == null) {
      return null;
    }
    DateTime today = DateTime.now();
    DateTime startBillDate = date!;

    if (repeatPattern == PaymentRate.monthly.value) {
      while (startBillDate.add(const Duration(days: 31)).isBefore(today)) {
        startBillDate = DateTime(
            startBillDate.year, startBillDate.month + 1, startBillDate.day);
      }
    } else if (repeatPattern == PaymentRate.yearly.value) {
      while (startBillDate.add(const Duration(days: 366)).isBefore(today)) {
        startBillDate = DateTime(
            startBillDate.year + 1, startBillDate.month, startBillDate.day);
      }
    } else {
      return null;
    }
    return startBillDate;
  }

  Future<Color> getDominantColorFromUrl({String customUrl = ""}) async {
    var response =
        await http.get(Uri.parse(customUrl.isNotEmpty ? customUrl : url!));
    if (response.statusCode == 200) {
      img.Image? image = img.decodeImage(response.bodyBytes);
      if (image != null) {
        var paletteGenerator = await PaletteGenerator.fromImageProvider(
            Image.network(customUrl.isNotEmpty ? customUrl : url!).image);
        return paletteGenerator.dominantColor?.color ?? Colors.grey;
      }
    }
    return Colors.grey;
  }

  String getFaviconUrl() {
    return 'https://www.google.com/s2/favicons?sz=64&domain_url=${Uri.parse(url!).host}';
  }

  DateTime getNextBillDate() {
    if (date == null) {
      return DateTime.now();
    }
    DateTime nextBillDate = date!;
    DateTime today = DateTime.now();

    if (repeatPattern == PaymentRate.yearly.value) {
      while (!nextBillDate.isAfter(today)) {
        nextBillDate = DateTime(
            nextBillDate.year + 1, nextBillDate.month, nextBillDate.day);
      }
    } else if (repeatPattern == PaymentRate.monthly.value) {
      while (!nextBillDate.isAfter(today)) {
        int newMonth = nextBillDate.month + 1;
        int newYear = nextBillDate.year;
        if (newMonth > 12) {
          newMonth = 1;
          newYear++;
        }
        nextBillDate = DateTime(newYear, newMonth, nextBillDate.day);
        while (nextBillDate.month != newMonth) {
          nextBillDate = DateTime(newYear, newMonth, nextBillDate.day - 1);
        }
      }
    }
    return nextBillDate;
  }

  Widget buildImage({
    double width = 40,
    double height = 40,
    BoxFit boxFit = BoxFit.cover,
    double errorImgSize = 40,
    double borderRadius = 8.0,
  }) {
    if (url == null || url!.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Icon(
          url == null
              ? CupertinoIcons.exclamationmark_triangle
              : Icons.account_balance_wallet_rounded,
          color: CupertinoColors.systemGrey,
          size: errorImgSize,
        ),
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: CachedNetworkImage(
          imageUrl: getFaviconUrl(),
          placeholder: (context, url) => const CupertinoActivityIndicator(),
          errorWidget: (context, url, error) => const Icon(
            CupertinoIcons.exclamationmark_triangle,
            color: CupertinoColors.systemGrey,
            size: 40,
          ),
          fit: boxFit,
          width: width,
          height: height,
        ),
      );
    }
  }

  Future<bool> hasCategories() async {
    final db = await PersistenceController.instance.database;
    var result = await db.rawQuery(
        'SELECT EXISTS(SELECT 1 FROM subscription_categories WHERE subscription_id = ?)',
        [id]);
    int exists = Sqflite.firstIntValue(result) ?? 0;
    return exists == 1;
  }

  Future<void> assignCategories(List<category.Category> categories) async {
    final db = await PersistenceController.instance.database;
    var categoryIds = categories.map((category) => category.id).toList();
    await db.transaction((txn) async {
      await txn.delete('subscription_categories',
          where: 'subscription_id = ?', whereArgs: [id]);
      for (var categoryId in categoryIds) {
        await txn.insert('subscription_categories', {'subscription_id': id, 'category_id': categoryId});
      }
    }).catchError((error) {
      debugPrint('Error assigning categories to subscription: $error');
    });
  }

  Future<List<category.Category>> get categories async {
    final db = await PersistenceController.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('categories', where: 'id IN (SELECT category_id FROM subscription_categories WHERE subscription_id = ?)', whereArgs: [id]);
    return List.generate(maps.length, (i) {
      return category.Category.fromJson(maps[i]);
    });
  }

  int countPayment() {
    if (date == null) {
      return 0;
    }
    final today = DateTime.now();
    DateTime nextBillDate = date!;
    int count = 0;
    if (repeatPattern == PaymentRate.yearly.value) {
      while (nextBillDate.isBefore(today)) {
        nextBillDate = DateTime(
            nextBillDate.year + 1, nextBillDate.month, nextBillDate.day);
        count++;
      }
    } else if (repeatPattern == PaymentRate.monthly.value) {
      while (nextBillDate.isBefore(today)) {
        nextBillDate = DateTime(
            nextBillDate.year, nextBillDate.month + 1, nextBillDate.day);
        count++;
      }
    }
    return count;
  }

  double sumPayment() {
    if (date == null) {
      return 0.0;
    }
    final today = DateTime.now();
    DateTime nextBillDate = date!;
    Duration interval;
    if (repeatPattern == PaymentRate.yearly.value) {
      interval = const Duration(days: 365);
    } else {
      interval = const Duration(days: 30);
    }

    double sum = 0;
    while (nextBillDate.isBefore(today)) {
      nextBillDate = nextBillDate.add(interval);
      sum += amount;
    }
    return sum;
  }

  PaymentRate getRepeatPattern() {
    return PaymentRate.findByName(repeatPattern!);
  }

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      amount: (json['amount'] as num).toDouble(),
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      isPaused: json['isPaused'] == 1,
      isPinned: json['isPinned'] == 1,
      notes: json['notes'],
      rememberCycle: RememberCycle.findByName(
              json['rememberCycle'] ?? RememberCycle.sameDay.value)
          .value,
      repeating: json['repeating'] == 1,
      repeatPattern: PaymentRate.findByName(json['repeatPattern']).value,
      timestamp:
          json['timestamp'] != null ? DateTime.parse(json['timestamp']) : null,
      title: json['title'],
      url: json['url'],
    );
  }

  factory Subscription.migrate(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      amount: (json['amount'] as num).toDouble(),
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      isPaused: json['isPaused'] == 1,
      isPinned: json['isPinned'] == 1,
      notes: json['notes'],
      rememberCycle:
          RememberCycle.migrate(json['remembercycle'].toString()).value,
      repeating: json['repeating'] == 1,
      repeatPattern:
          PaymentRate.findByName(json['repeatPattern'].toString()).value,
      timestamp:
          json['timestamp'] != null ? DateTime.parse(json['timestamp']) : null,
      title: json['title'],
      url: json['url'],
    );
  }

  Future<Subscription> save() async {
    final db = await PersistenceController.instance.database;
    if (id == null) {
      id = await db.insert('subscriptions', toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.update(
        'subscriptions',
        toJson(),
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    await PersistenceController.instance.syncWithCloud();
    return this;
  }

  Future<void> delete() async {
    if (kIsWeb) {
      throw UnsupportedError("Database is not supported on the web");
    }
    final db = await PersistenceController.instance.database;
    await db.delete(
      'subscriptions',
      where: 'id = ?',
      whereArgs: [id],
    );
    await PersistenceController.instance.syncWithCloud();
  }

  static Future<List<Subscription>> all() async {
    if (kIsWeb) {
      throw UnsupportedError("Database is not supported on the web");
    }
    final db = await PersistenceController.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('subscriptions');
    return List.generate(maps.length, (i) {
      return Subscription.fromJson(maps[i]);
    });
  }


  String displayConvertedPrice(Currency currency) {
    String priceString = amount.toStringAsFixed(2);
    return repeatPattern == PaymentRate.yearly.value
        ? '$priceString ${currency.symbol}/${Intl.message('Y')}'
        : '$priceString ${currency.symbol}/${Intl.message('M')}';
  }
}

extension on DateTime {
  bool isValidDate() {
    try {
      DateTime(year, month, day);
      return true;
    } catch (e) {
      return false;
    }
  }
}
