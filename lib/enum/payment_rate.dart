import 'package:easy_wallet/class/translatable_enum.dart';

/// How often a subscription is billed.
///
/// Every interval is a whole number of months, and [monthsPerPeriod] is what
/// the rest of the app calculates with. Comparing against single values, the
/// way this used to be done, silently treats any interval nobody thought of as
/// monthly — and a quarterly subscription counted monthly is three times too
/// expensive in every total the app shows.
enum PaymentRate with TranslatableEnum {
  monthly(
      value: 'monthly', monthsPerPeriod: 1, shortLabelKey: 'rateShortMonthly'),
  quarterly(
      value: 'quarterly',
      monthsPerPeriod: 3,
      shortLabelKey: 'rateShortQuarterly'),
  fourMonthly(
      value: 'fourMonthly',
      monthsPerPeriod: 4,
      shortLabelKey: 'rateShortFourMonthly'),
  halfYearly(
      value: 'halfYearly',
      monthsPerPeriod: 6,
      shortLabelKey: 'rateShortHalfYearly'),
  yearly(
      value: 'yearly', monthsPerPeriod: 12, shortLabelKey: 'rateShortYearly');

  const PaymentRate({
    required this.value,
    required this.monthsPerPeriod,
    required this.shortLabelKey,
  });

  @override
  final String value;

  /// Months from one billing to the next.
  final int monthsPerPeriod;

  /// Translation key of the abbreviation shown next to a price, e.g. "/3M".
  final String shortLabelKey;

  /// What [amount], billed once per period, works out to per month.
  double perMonth(double amount) => amount * 1.0 / monthsPerPeriod;

  /// What [amount], billed once per period, works out to per year.
  double perYear(double amount) => amount * 12 / monthsPerPeriod;

  /// The billing date [step] periods after [anchor].
  ///
  /// The day of month of [anchor] stays the anchor: a subscription starting on
  /// the 31st falls on the 28th in February but returns to the 31st in March
  /// instead of drifting earlier with every short month.
  ///
  /// Lives here rather than in a calculation somewhere, because every part of
  /// the app that asks "when is this billed next" has to answer it the same
  /// way — the calendar, the reminders, the widget and the detail view used to
  /// each have their own slightly different version.
  DateTime shift(DateTime anchor, int step) {
    final months = anchor.month - 1 + step * monthsPerPeriod;
    final year = anchor.year + months ~/ 12;
    final month = months % 12 + 1;
    final lastDayOfMonth = DateTime(year, month + 1, 0).day;

    return DateTime(
      year,
      month,
      anchor.day <= lastDayOfMonth ? anchor.day : lastDayOfMonth,
    );
  }

  static PaymentRate findByName(String name) {
    return PaymentRate.values.firstWhere(
      (e) => e.value == name,
      orElse: () => PaymentRate.monthly,
    );
  }

  static List<String> all() {
    return PaymentRate.values.map((e) => e.value).toList();
  }
}
