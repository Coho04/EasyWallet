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

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      amount: (json['amount'] as num).toDouble(),
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      isPaused: json['isPaused'] == 1,
      isPinned: json['isPinned'] == 1,
      notes: json['notes'],
      rememberCycle: RememberCycle.findByName(json['rememberCycle'] ?? RememberCycle.sameDay.value).value,
      repeating: json['repeating'] == 1,
      repeatPattern: PaymentRate.findByName(json['repeatPattern']).value,
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : null,
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
      rememberCycle: RememberCycle.migrate(json['remembercycle'].toString()).value,
      repeating: json['repeating'] == 1,
      repeatPattern: PaymentRate.findByName(json['repeatPattern'].toString()).value,
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : null,
      title: json['title'],
      url: json['url'],
    );
  }
}
