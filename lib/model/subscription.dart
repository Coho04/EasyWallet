import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_wallet/enum/payment_rate.dart';
import 'package:easy_wallet/enum/remember_cycle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:palette_generator/palette_generator.dart';

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
    Duration interval =
        Duration(days: repeatPattern == PaymentRate.yearly.value ? 365 : 30);
    while (nextBillDate.isBefore(today)) {
      nextBillDate = nextBillDate.add(interval);
    }
    return nextBillDate.difference(today).inDays;
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
    var response = await http.get(Uri.parse(customUrl.isNotEmpty ? customUrl : url!));
    if (response.statusCode == 200) {
      img.Image? image = img.decodeImage(response.bodyBytes);
      if (image != null) {
        var paletteGenerator =
            await PaletteGenerator.fromImageProvider(Image.network(customUrl.isNotEmpty ? customUrl : url!).image);
        return paletteGenerator.dominantColor?.color ?? Colors.grey;
      }
    }
    return Colors.grey;
  }

  String getFaviconUrl() {
    return 'https://www.google.com/s2/favicons?sz=64&domain_url=${Uri.parse(url!).host}';
  }

  DateTime getNextBillDate() {
    if (date == null) return DateTime.now();
    DateTime nextBillDate = date!;
    DateTime today = DateTime.now();
    Duration interval = repeatPattern == PaymentRate.yearly.value
        ? const Duration(days: 365)
        : const Duration(days: 30);
    while (nextBillDate.isBefore(today)) {
      nextBillDate = nextBillDate.add(interval);
    }
    return nextBillDate;
  }

  Widget buildImage(
      {double width = 40,
      double height = 40,
      BoxFit boxFit = BoxFit.cover,
      double errorImgSize = 40}) {
    if (url == null) {
      return Icon(
        CupertinoIcons.exclamationmark_triangle,
        color: CupertinoColors.systemGrey,
        size: errorImgSize,
      );
    } else if (url!.isEmpty) {
      return Icon(
        Icons.account_balance_wallet_rounded,
        color: CupertinoColors.systemGrey,
        size: errorImgSize,
      );
    } else {
      return CachedNetworkImage(
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
      );
    }
  }

  int countPayment() {
    if (date == null) {
      return 0;
    }
    final today = DateTime.now();
    DateTime nextBillDate = date!;
    Duration interval;
    if (repeatPattern == PaymentRate.yearly.value) {
      interval = const Duration(days: 365);
    } else {
      interval = const Duration(days: 30);
    }

    int count = 0;
    while (nextBillDate.isBefore(today)) {
      nextBillDate = nextBillDate.add(interval);
      count++;
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
}
