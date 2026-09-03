import 'package:easy_wallet/class/exchange_rates.dart';
import 'package:easy_wallet/class/money.dart';
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

  /// Last day the subscription is billed, inclusive. Null means open ended.
  DateTime? endDate;

  /// Last day of a free trial, inclusive. Billing starts after it.
  DateTime? trialEndDate;

  /// How many people share the cost. Null or 1 means it is paid alone.
  int? splitCount;

  /// Currency this subscription is billed in. Null means the app's currency.
  String? currencyCode;
  bool isPaused;
  bool isPinned;
  String? notes;
  String? rememberCycle;
  String? paymentMethode;
  bool repeating;
  String? repeatPattern;
  DateTime? timestamp;
  String title;
  String? url;

  Subscription({
    this.id,
    required this.amount,
    this.date,
    this.endDate,
    this.trialEndDate,
    this.splitCount,
    this.currencyCode,
    required this.isPaused,
    required this.isPinned,
    this.notes,
    this.rememberCycle,
    this.paymentMethode,
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
      'endDate': endDate?.toIso8601String(),
      'trialEndDate': trialEndDate?.toIso8601String(),
      'splitCount': splitCount,
      'currencyCode': currencyCode,
      'isPaused': isPaused ? 1 : 0,
      'isPinned': isPinned ? 1 : 0,
      'notes': notes,
      'rememberCycle': rememberCycle,
      'paymentMethode': paymentMethode,
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

  /// Whether the subscription has run out on [day]. The end date is
  /// inclusive, so the subscription is still active on that day itself.
  bool isExpiredOn(DateTime day) {
    final end = endDate;
    if (end == null) {
      return false;
    }
    return DateTime(day.year, day.month, day.day)
        .isAfter(DateTime(end.year, end.month, end.day));
  }

  bool get isExpired => isExpiredOn(DateTime.now());

  /// This user's share expressed in [targetCurrency]. Without rates, or when
  /// the subscription has no currency of its own, the amount is used as is.
  double shareIn(String? targetCurrency, ExchangeRates? rates) {
    final share = shareOfAmount;
    final from = currencyCode;
    if (from == null || targetCurrency == null || rates == null) {
      return share;
    }
    return rates.convert(share, from: from, to: targetCurrency);
  }

  /// The part of [amount] this user carries once the cost is shared.
  double get shareOfAmount {
    final count = splitCount;
    if (count == null || count <= 1) {
      return amount;
    }
    return amount / count;
  }

  /// Whether the free trial is still running on [day]. The trial end date is
  /// inclusive, so the last free day is the date itself.
  bool isInTrialOn(DateTime day) {
    final trialEnd = trialEndDate;
    if (trialEnd == null) {
      return false;
    }
    return !DateTime(day.year, day.month, day.day)
        .isAfter(DateTime(trialEnd.year, trialEnd.month, trialEnd.day));
  }

  bool get isInTrial => isInTrialOn(DateTime.now());

  /// The day up to which this subscription is billed: the end date once it has
  /// passed, otherwise [asOf].
  DateTime _billedUntil(DateTime asOf) {
    final end = endDate;
    if (end != null && end.isBefore(asOf)) {
      return end;
    }
    return asOf;
  }

  int countPayment({DateTime? asOf}) {
    if (date == null) {
      return 0;
    }
    final today = _billedUntil(asOf ?? DateTime.now());
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

  double sumPayment({DateTime? asOf}) {
    if (date == null) {
      return 0.0;
    }
    final today = _billedUntil(asOf ?? DateTime.now());
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
      endDate:
          json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      trialEndDate: json['trialEndDate'] != null
          ? DateTime.parse(json['trialEndDate'])
          : null,
      splitCount: json['splitCount'],
      currencyCode: json['currencyCode'],
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
      endDate:
          json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      trialEndDate: json['trialEndDate'] != null
          ? DateTime.parse(json['trialEndDate'])
          : null,
      splitCount: json['splitCount'],
      currencyCode: json['currencyCode'],
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
      await _recordPrice(db);
    } else {
      await _recordPriceIfChanged(db);
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

/// Writes the current price into the history. Subscriptions get more
  /// expensive over time and that is precisely what people track them for.
  Future<void> _recordPrice(DatabaseExecutor db) async {
    await db.insert('price_history', {
      'subscription_id': id,
      'amount': amount,
      'currencyCode': currencyCode,
      'changedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _recordPriceIfChanged(DatabaseExecutor db) async {
    final rows = await db.query(
      'subscriptions',
      columns: ['amount'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return;
    }
    final stored = (rows.first['amount'] as num?)?.toDouble();
    if (stored != null && (stored - amount).abs() < 0.001) {
      return;
    }
    await _recordPrice(db);
  }

  /// Every recorded price of this subscription, oldest first.
  Future<List<PriceChange>> priceHistory() async {
    if (id == null) {
      return [];
    }
    final db = await PersistenceController.instance.database;
    final rows = await db.query(
      'price_history',
      where: 'subscription_id = ?',
      whereArgs: [id],
      orderBy: 'changedAt ASC',
    );
    return rows.map(PriceChange.fromJson).toList();
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
    String priceString = Money.format(amount, currency.symbol);
    return repeatPattern == PaymentRate.yearly.value
        ? '$priceString/${Intl.message('Y')}'
        : '$priceString/${Intl.message('M')}';
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

/// One recorded price of a subscription.
class PriceChange {
  const PriceChange({
    required this.amount,
    required this.changedAt,
    this.currencyCode,
  });

  final double amount;
  final DateTime changedAt;
  final String? currencyCode;

  factory PriceChange.fromJson(Map<String, dynamic> json) => PriceChange(
        amount: (json['amount'] as num).toDouble(),
        changedAt: DateTime.parse(json['changedAt']),
        currencyCode: json['currencyCode'],
      );
}
