import 'package:easy_wallet/class/translatable_enum.dart';

/// How often a subscription is billed.
///
/// An interval is either a whole number of days ([daysPerPeriod], for the
/// week-based ones) or a whole number of months ([monthsPerPeriod]) — never
/// both. [perMonth], [perYear] and [shift] are what the rest of the app
/// calculates with. Comparing against single values, the way this used to be
/// done, silently treats any interval nobody thought of as monthly — and a
/// quarterly subscription counted monthly is three times too expensive in
/// every total the app shows.
enum PaymentRate with TranslatableEnum {
  weekly(value: 'weekly', daysPerPeriod: 7, shortLabelKey: 'rateShortWeekly'),
  biweekly(
    value: 'biweekly',
    daysPerPeriod: 14,
    shortLabelKey: 'rateShortBiweekly',
  ),
  fourWeekly(
    value: 'fourWeekly',
    daysPerPeriod: 28,
    shortLabelKey: 'rateShortFourWeekly',
  ),
  monthly(
    value: 'monthly',
    monthsPerPeriod: 1,
    shortLabelKey: 'rateShortMonthly',
  ),
  bimonthly(
    value: 'bimonthly',
    monthsPerPeriod: 2,
    shortLabelKey: 'rateShortBimonthly',
  ),
  quarterly(
    value: 'quarterly',
    monthsPerPeriod: 3,
    shortLabelKey: 'rateShortQuarterly',
  ),
  fourMonthly(
    value: 'fourMonthly',
    monthsPerPeriod: 4,
    shortLabelKey: 'rateShortFourMonthly',
  ),
  halfYearly(
    value: 'halfYearly',
    monthsPerPeriod: 6,
    shortLabelKey: 'rateShortHalfYearly',
  ),
  yearly(
    value: 'yearly',
    monthsPerPeriod: 12,
    shortLabelKey: 'rateShortYearly',
  ),
  biennial(
    value: 'biennial',
    monthsPerPeriod: 24,
    shortLabelKey: 'rateShortBiennial',
  );

  const PaymentRate({
    required this.value,
    this.monthsPerPeriod = 0,
    this.daysPerPeriod = 0,
    required this.shortLabelKey,
  }) : assert((monthsPerPeriod > 0) != (daysPerPeriod > 0));

  /// Average length of a Gregorian year, so 52 weekly payments plus the odd
  /// 53rd one average out instead of a year always counting exactly 52.
  static const double daysPerYear = 365.2425;

  @override
  final String value;

  /// Months from one billing to the next, or 0 for a week-based interval.
  final int monthsPerPeriod;

  /// Days from one billing to the next, or 0 for a month-based interval.
  final int daysPerPeriod;

  /// Translation key of the abbreviation shown next to a price, e.g. "/3M".
  final String shortLabelKey;

  /// How many times per year this interval bills, on average.
  double get periodsPerYear =>
      monthsPerPeriod > 0 ? 12 / monthsPerPeriod : daysPerYear / daysPerPeriod;

  /// What [amount], billed once per period, works out to per month.
  double perMonth(double amount) => amount * periodsPerYear / 12;

  /// What [amount], billed once per period, works out to per year.
  double perYear(double amount) => amount * periodsPerYear;

  /// The billing date [step] periods after [anchor].
  ///
  /// For month-based intervals the day of month of [anchor] stays the anchor:
  /// a subscription starting on the 31st falls on the 28th in February but
  /// returns to the 31st in March instead of drifting earlier with every short
  /// month. Week-based intervals count calendar days, not a Duration, so a
  /// daylight saving change cannot move a billing to 23:00 the day before.
  ///
  /// Lives here rather than in a calculation somewhere, because every part of
  /// the app that asks "when is this billed next" has to answer it the same
  /// way — the calendar, the reminders, the widget and the detail view used to
  /// each have their own slightly different version.
  DateTime shift(DateTime anchor, int step) {
    if (daysPerPeriod > 0) {
      return DateTime(
        anchor.year,
        anchor.month,
        anchor.day + step * daysPerPeriod,
      );
    }

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
