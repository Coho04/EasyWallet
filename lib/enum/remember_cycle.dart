enum RememberCycle {
  sameDay(value: 'same_day'),
  dayBefore(value: 'day_before'),
  twoDaysBefore(value: 'two_days_before'),
  weekBefore(value: 'week_before');

  const RememberCycle({
    required this.value,
  });

  final String value;

  static List<String> all() {
    return RememberCycle.values.map((e) => e.value).toList();
  }
}
