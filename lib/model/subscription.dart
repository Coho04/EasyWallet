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
      amount: json['amount'],
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      isPaused: json['isPaused'] == 1,
      isPinned: json['isPinned'] == 1,
      notes: json['notes'],
      rememberCycle: json['rememberCycle'],
      repeating: json['repeating'] == 1,
      repeatPattern: json['repeatPattern'],
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : null,
      title: json['title'],
      url: json['url'],
    );
  }
}
