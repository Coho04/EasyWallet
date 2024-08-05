import 'package:intl/intl.dart';

enum RememberCycle {
  sameDay(value: 'same_day', camelCase: 'sameDay', migration: 'SameDay'),
  dayBefore(
      value: 'day_before', camelCase: 'dayBefore', migration: 'OneDayBefore'),
  twoDaysBefore(
      value: 'two_days_before',
      camelCase: 'twoDaysBefore',
      migration: 'TwoDaysBefore'),
  weekBefore(
      value: 'week_before',
      camelCase: 'weekBefore',
      migration: 'OneWeekBefore');

  const RememberCycle({
    required this.value,
    required this.camelCase,
    required this.migration,
  });

  final String value;
  final String camelCase;
  final String migration;

  String translate() {
    return Intl.message(camelCase);
  }

  static RememberCycle migrate(String? value) {
    if (value == null) {
      return RememberCycle.dayBefore;
    }
    return RememberCycle.values.firstWhere(
      (e) => e.migration == value,
      orElse: () => RememberCycle.dayBefore,
    );
  }

  static RememberCycle findByName(String name) {
    return RememberCycle.values.firstWhere(
      (e) => e.value == name,
      orElse: () => RememberCycle.dayBefore,
    );
  }

  static List<String> all() {
    return RememberCycle.values.map((e) => e.value).toList();
  }
}
