import 'package:intl/intl.dart';

enum RememberCycle {
  sameDay(value: 'same_day', camelCase: 'sameDay'),
  dayBefore(value: 'day_before', camelCase: 'dayBefore'),
  twoDaysBefore(value: 'two_days_before', camelCase: 'twoDaysBefore'),
  weekBefore(value: 'week_before', camelCase: 'weekBefore');

  const RememberCycle({
    required this.value,
    required this.camelCase,
  });

  final String value;
  final String camelCase;

  String translate() {
    return Intl.message(camelCase);
  }

  static List<String> all() {
    return RememberCycle.values.map((e) => e.value).toList();
  }
}
