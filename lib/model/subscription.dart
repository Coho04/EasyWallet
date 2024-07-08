import 'package:easy_wallet/enum/payment_rate.dart';
import 'package:easy_wallet/enum/remember_cycle.dart';

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
    final today = DateTime.now();
    final startBillDate = date!;
    DateTime potentialPreviousBillDate = startBillDate;
    Duration interval;
    if (repeatPattern == PaymentRate.monthly.value) {
      interval = const Duration(days: 30);
    } else if (repeatPattern == PaymentRate.yearly.value) {
      interval = const Duration(days: 365);
    } else {
      return null;
    }

    DateTime? lastBillDate;
    while (potentialPreviousBillDate.isBefore(today)) {
      lastBillDate = potentialPreviousBillDate;
      potentialPreviousBillDate = potentialPreviousBillDate.add(interval);
    }

    return lastBillDate;
  }

  DateTime? calculateNextBillDate() {
    if (date == null) {
      return null;
    }
    final today = DateTime.now();
    DateTime nextBillDate = date!;
    Duration interval;
    if (repeatPattern == PaymentRate.monthly.value) {
      interval = const Duration(days: 30);
    } else if (repeatPattern == PaymentRate.yearly.value) {
      interval = const Duration(days: 365);
    } else {
      return null;
    }

    while (nextBillDate.isBefore(today)) {
      nextBillDate = nextBillDate.add(interval);
    }
    return nextBillDate;
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
